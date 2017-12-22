# --
# Copyright (C) 2001-2017 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::ArticleCheck::PGP;

use strict;
use warnings;

use MIME::Parser;
use Kernel::System::EmailParser;
use Kernel::System::VariableCheck qw(:all);
use Kernel::Language qw(Translatable);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Crypt::PGP',
    'Kernel::System::Log',
    'Kernel::System::Ticket::Article',
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # get needed params
    for my $Needed (qw(UserID ArticleID)) {
        if ( $Param{$Needed} ) {
            $Self->{$Needed} = $Param{$Needed};
        }
        else {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
        }
    }

    return $Self;
}

sub Check {
    my ( $Self, %Param ) = @_;
    my %SignCheck;
    my @Return;

    # get config object
    my $ConfigObject = $Param{ConfigObject} || $Kernel::OM->Get('Kernel::Config');

    # check if pgp is enabled
    return if !$ConfigObject->Get('PGP');

    my $ArticleObject = $Param{ArticleObject} || $Kernel::OM->Get('Kernel::System::Ticket::Article');

    my $ArticleBackendObject = $ArticleObject->BackendForArticle(
        TicketID  => $Param{Article}->{TicketID},
        ArticleID => $Param{Article}->{ArticleID},
    );

    # check if article is an email
    return if $ArticleBackendObject->ChannelNameGet() ne 'Email';

    # get needed objects
    my $PGPObject = $Kernel::OM->Get('Kernel::System::Crypt::PGP');

    # check inline pgp crypt
    if ( $Param{Article}->{Body} && $Param{Article}->{Body} =~ /\A[\s\n]*^-----BEGIN PGP MESSAGE-----/m ) {

        # check sender (don't decrypt sent emails)
        if ( $Param{Article}->{SenderType} =~ /(agent|system)/i ) {

            # return info
            return (
                {
                    Key   => Translatable('Crypted'),
                    Value => Translatable('Sent message encrypted to recipient!'),
                }
            );
        }
        my %Decrypt = $PGPObject->Decrypt( Message => $Param{Article}->{Body} );
        if ( $Decrypt{Successful} ) {

            # remember to result
            $Self->{Result} = \%Decrypt;
            $Param{Article}->{Body} = $Decrypt{Data};

            # updated article body
            $ArticleBackendObject->ArticleUpdate(
                TicketID  => $Param{Article}->{TicketID},
                ArticleID => $Self->{ArticleID},
                Key       => 'Body',
                Value     => $Decrypt{Data},
                UserID    => $Self->{UserID},
            );

            # get a list of all article attachments
            my %Index = $ArticleBackendObject->ArticleAttachmentIndex(
                ArticleID => $Self->{ArticleID},
            );

            my @Attachments;
            if ( IsHashRefWithData( \%Index ) ) {
                for my $FileID ( sort keys %Index ) {

                    # get attachment details
                    my %Attachment = $ArticleBackendObject->ArticleAttachment(
                        ArticleID => $Self->{ArticleID},
                        FileID    => $FileID,
                    );

                    # store attachemnts attributes that might change after decryption
                    my $AttachmentContent  = $Attachment{Content};
                    my $AttachmentFilename = $Attachment{Filename};

                    # try to decrypt the attachment, non ecrypted attachments will succeed too.
                    %Decrypt = $PGPObject->Decrypt( Message => $Attachment{Content} );

                    if ( $Decrypt{Successful} ) {

                        # set decrypted content
                        $AttachmentContent = $Decrypt{Data};

                        # remove .pgp .gpg or asc extensions (if any)
                        $AttachmentFilename =~ s{ (\. [^\.]+) \. (?: pgp|gpg|asc) \z}{$1}msx;
                    }

                    # remember decrypted attachement, to add it later
                    push @Attachments, {
                        %Attachment,
                        Content   => $AttachmentContent,
                        Filename  => $AttachmentFilename,
                        ArticleID => $Self->{ArticleID},
                        UserID    => $Self->{UserID},
                    };
                }

                # delete crypted attachments
                $ArticleBackendObject->ArticleDeleteAttachment(
                    ArticleID => $Self->{ArticleID},
                    UserID    => $Self->{UserID},
                );

                # write decrypted attachments to the storage
                for my $Attachment (@Attachments) {
                    $ArticleBackendObject->ArticleWriteAttachment( %{$Attachment} );
                }
            }

            push(
                @Return,
                {
                    Key   => Translatable('Crypted'),
                    Value => $Decrypt{Message},
                    %Decrypt,
                },
            );
        }
        else {

            # return with error
            return (
                {
                    Key   => Translatable('Crypted'),
                    Value => $Decrypt{Message},
                    %Decrypt,
                }
            );
        }
    }

    # check inline pgp signature (but ignore if is in quoted text)
    if (
        $Param{Article}->{Body}
        && $Param{Article}->{Body} =~ m{ ^\s* -----BEGIN [ ] PGP [ ] SIGNED [ ] MESSAGE----- }xms
        )
    {

        # get original message
        my $Message = $ArticleBackendObject->ArticlePlain(
            ArticleID => $Self->{ArticleID},
            UserID    => $Self->{UserID},
        );

        # create local email parser object
        my $ParserObject = Kernel::System::EmailParser->new(
            Email => $Message,
        );

        # get the charset of the original message
        my $Charset = $ParserObject->GetCharset();

        # verify message PGP signature
        %SignCheck = $PGPObject->Verify(
            Message => $Param{Article}->{Body},
            Charset => $Charset
        );

        if (%SignCheck) {

            # remember to result
            $Self->{Result} = \%SignCheck;
        }
        else {

            # return with error
            return (
                {
                    Key   => Translatable('Signed'),
                    Value => Translatable('"PGP SIGNED MESSAGE" header found, but invalid!'),
                }
            );
        }
    }

    # check mime pgp
    else {

        # check body
        # if body =~ application/pgp-encrypted
        # if crypted, decrypt it
        # remember that it was crypted!

        # Get plain article/email from filesystem storage.
        my $Message = $ArticleBackendObject->ArticlePlain(
            ArticleID => $Self->{ArticleID},
            UserID    => $Self->{UserID},
        );
        return if !$Message;

        my $Parser = MIME::Parser->new();
        $Parser->decode_headers(0);
        $Parser->extract_nested_messages(0);
        $Parser->output_to_core('ALL');

        # prevent modification of body by parser - required for bug #11755
        $Parser->decode_bodies(0);
        my $Entity = $Parser->parse_data($Message);
        $Parser->decode_bodies(1);
        my $Head = $Entity->head();
        $Head->unfold();
        $Head->combine('Content-Type');
        my $ContentType = $Head->get('Content-Type');

        # check if we need to decrypt it
        if (
            $ContentType
            && $ContentType =~ /multipart\/encrypted/i
            && $ContentType =~ /application\/pgp/i
            )
        {

            # check sender (don't decrypt sent emails)
            if ( $Param{Article}->{SenderType} && $Param{Article}->{SenderType} =~ /(agent|system)/i ) {

                # return info
                return (
                    {
                        Key        => Translatable('Crypted'),
                        Value      => Translatable('Sent message encrypted to recipient!'),
                        Successful => 1,
                    }
                );
            }

            # get crypted part of the mail
            my $Crypted = $Entity->parts(1)->as_string();

            # decrypt it
            my %Decrypt = $PGPObject->Decrypt(
                Message => $Crypted,
            );
            if ( $Decrypt{Successful} ) {
                $Entity = $Parser->parse_data( $Decrypt{Data} );
                my $Head = $Entity->head();
                $Head->unfold();
                $Head->combine('Content-Type');
                $ContentType = $Head->get('Content-Type');

                # use a copy of the Entity to get the body, otherwise the original mail content
                # could be altered and a signature verify could fail. See Bug#9954
                my $EntityCopy = $Entity->dup();

                my $ParserObject = Kernel::System::EmailParser->new(
                    Entity => $EntityCopy,
                );

                my $Body = $ParserObject->GetMessageBody();

                # updated article body
                $ArticleBackendObject->ArticleUpdate(
                    TicketID  => $Param{Article}->{TicketID},
                    ArticleID => $Self->{ArticleID},
                    Key       => 'Body',
                    Value     => $Body,
                    UserID    => $Self->{UserID},
                );

                # delete crypted attachments
                $ArticleBackendObject->ArticleDeleteAttachment(
                    ArticleID => $Self->{ArticleID},
                    UserID    => $Self->{UserID},
                );

                # write attachments to the storage
                for my $Attachment ( $ParserObject->GetAttachments() ) {
                    $ArticleBackendObject->ArticleWriteAttachment(
                        %{$Attachment},
                        ArticleID => $Self->{ArticleID},
                        UserID    => $Self->{UserID},
                    );
                }

                push(
                    @Return,
                    {
                        Key   => Translatable('Crypted'),
                        Value => $Decrypt{Message},
                        %Decrypt,
                    },
                );
            }
            else {
                push(
                    @Return,
                    {
                        Key   => Translatable('Crypted'),
                        Value => $Decrypt{Message},
                        %Decrypt,
                    },
                );
            }
        }
        if (
            $ContentType
            && $ContentType =~ /multipart\/signed/i
            && $ContentType =~ /application\/pgp/i
            && $Entity->parts(0)
            && $Entity->parts(1)
            )
        {

            my $SignedText    = $Entity->parts(0)->as_string();
            my $SignatureText = $Entity->parts(1)->body_as_string();

            # according to RFC3156 all line endings MUST be CR/LF
            $SignedText =~ s/\x0A/\x0D\x0A/g;
            $SignedText =~ s/\x0D+/\x0D/g;

            %SignCheck = $PGPObject->Verify(
                Message => $SignedText,
                Sign    => $SignatureText,
            );
        }
    }
    if (%SignCheck) {

        # return result
        push(
            @Return,
            {
                Key   => Translatable('Signed'),
                Value => $SignCheck{Message},
                %SignCheck,
            },
        );
    }
    return @Return;
}

sub Filter {
    my ( $Self, %Param ) = @_;

    # remove signature if one is found
    if ( $Self->{Result}->{SignatureFound} ) {

        # remove pgp begin signed message
        $Param{Article}->{Body} =~ s/^-----BEGIN\sPGP\sSIGNED\sMESSAGE-----.+?Hash:\s.+?$//sm;

        # remove pgp inline sign
        $Param{Article}->{Body}
            =~ s/^-----BEGIN\sPGP\sSIGNATURE-----.+?-----END\sPGP\sSIGNATURE-----//sm;
    }
    return 1;
}

1;
