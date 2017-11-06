# --
# Copyright (C) 2001-2017 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

use strict;
use warnings;
use utf8;

use vars (qw($Self));

use Kernel::System::VariableCheck qw(:all);

my $Selenium = $Kernel::OM->Get('Kernel::System::UnitTest::Selenium');

$Selenium->RunTest(
    sub {

        my $Helper                    = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
        my $CustomerCompanyObject     = $Kernel::OM->Get('Kernel::System::CustomerCompany');
        my $DynamicFieldObject        = $Kernel::OM->Get('Kernel::System::DynamicField');
        my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');
        my $CustomerUserObject        = $Kernel::OM->Get('Kernel::System::CustomerUser');
        my $ConfigObject              = $Kernel::OM->Get('Kernel::Config');
        my $LanguageObject            = $Kernel::OM->Get('Kernel::Language');

        $Helper->ConfigSettingChange(
            Key   => 'CheckEmailAddresses',
            Value => 0,
        );

        my $RandomNumber = $Helper->GetRandomNumber();

        my @DynamicFields = (
            {
                Name       => 'TestText' . $RandomNumber,
                Label      => 'TestText' . $RandomNumber,
                FieldOrder => 9990,
                FieldType  => 'Text',
                ObjectType => 'CustomerUser',
                Config     => {
                    DefaultValue => '',
                    Link         => '',
                },
                Reorder => 1,
                ValidID => 1,
                UserID  => 1,
            },
            {
                Name       => 'TestDropdown' . $RandomNumber,
                Label      => 'TestDropdown' . $RandomNumber,
                FieldOrder => 9990,
                FieldType  => 'Dropdown',
                ObjectType => 'CustomerUser',
                Config     => {
                    DefaultValue   => '',
                    Link           => '',
                    PossibleNone   => 0,
                    PossibleValues => {
                        0 => 'No',
                        1 => 'Yes',
                    },
                    TranslatableValues => 1,
                },
                Reorder => 1,
                ValidID => 1,
                UserID  => 1,
            },
            {
                Name       => 'TestMultiselect' . $RandomNumber,
                Label      => 'TestMultiselect' . $RandomNumber,
                FieldOrder => 9990,
                FieldType  => 'Multiselect',
                ObjectType => 'CustomerUser',
                Config     => {
                    DefaultValue   => '',
                    Link           => '',
                    PossibleNone   => 0,
                    PossibleValues => {
                        'a' => 'a',
                        'b' => 'b',
                        'c' => 'c',
                        'd' => 'd',
                    },
                    TranslatableValues => 1,
                },
                Reorder => 1,
                ValidID => 1,
                UserID  => 1,
            },
            {
                Name       => 'TestDate' . $RandomNumber,
                Label      => 'TestDate' . $RandomNumber,
                FieldOrder => 9990,
                FieldType  => 'Date',
                ObjectType => 'CustomerUser',
                Config     => {
                    DefaultValue  => 0,
                    YearsInFuture => 0,
                    YearsInPast   => 0,
                    YearsPeriod   => 0,
                },
                Reorder => 1,
                ValidID => 1,
                UserID  => 1,
            },
            {
                Name       => 'TestDateTime' . $RandomNumber,
                Label      => 'TestDateTime' . $RandomNumber,
                FieldOrder => 9990,
                FieldType  => 'DateTime',
                ObjectType => 'CustomerUser',
                Config     => {
                    DefaultValue  => 0,
                    YearsInFuture => 0,
                    YearsInPast   => 0,
                    YearsPeriod   => 0,
                },
                Reorder => 1,
                ValidID => 1,
                UserID  => 1,
            },
            {
                Name       => 'CompanyMultiselect' . $RandomNumber,
                Label      => 'CompanyMultiselect' . $RandomNumber,
                FieldOrder => 9990,
                FieldType  => 'Multiselect',
                ObjectType => 'CustomerCompany',
                Config     => {
                    DefaultValue   => '',
                    Link           => '',
                    PossibleNone   => 0,
                    PossibleValues => {
                        '100' => '100',
                        '200' => '200',
                        '300' => '300',
                        '400' => '400',
                    },
                    TranslatableValues => 1,
                },
                Reorder => 1,
                ValidID => 1,
                UserID  => 1,
            },
        );

        # Get the customer company config and customer user config to add the dynamic fields to the map.
        my $CustomerCompanyConfig = $Kernel::OM->Get('Kernel::Config')->Get('CustomerCompany');
        my $CustomerUserConfig    = $Kernel::OM->Get('Kernel::Config')->Get('CustomerUser');

        my @DynamicFieldIDs;
        my @DynamicFieldCustomerCompanySearchFields;
        my @DynamicFieldCustomerUserSearchFields;

        # Create test dynamic field of type date
        for my $DynamicField (@DynamicFields) {

            my $DynamicFieldID = $DynamicFieldObject->DynamicFieldAdd(
                %{$DynamicField},
            );

            $Self->True(
                $DynamicFieldID,
                "Dynamic field $DynamicField->{Name} - ID $DynamicFieldID - created",
            );

            push @DynamicFieldIDs, $DynamicFieldID;

            if ( $DynamicField->{ObjectType} eq 'CustomerCompany' ) {
                push @DynamicFieldCustomerCompanySearchFields, 'DynamicField_' . $DynamicField->{Name};

                push @{ $CustomerCompanyConfig->{Map} }, [
                    'DynamicField_' . $DynamicField->{Name}, undef, $DynamicField->{Name}, 0, 0, 'dynamic_field',
                    undef, 0,
                ];
            }
            else {
                push @DynamicFieldCustomerUserSearchFields, 'DynamicField_' . $DynamicField->{Name};

                push @{ $CustomerUserConfig->{Map} }, [
                    'DynamicField_' . $DynamicField->{Name}, undef, $DynamicField->{Name}, 0, 0, 'dynamic_field',
                    undef, 0,
                ];
            }
        }

        $CustomerCompanyConfig->{Selections}->{CustomerCompanyCountry} = {
            'Austria'       => 'Austria',
            'Belgium'       => 'Belgium',
            'Germany'       => 'Germany',
            'United States' => 'United States',
        };

        $Helper->ConfigSettingChange(
            Key   => 'CustomerCompany',
            Value => $CustomerCompanyConfig,
        );

        $CustomerUserConfig->{Selections}->{UserTitle} = {
            'Mr.'  => 'Mr.',
            'Mrs.' => 'Mrs.',
        };
        $CustomerUserConfig->{Selections}->{UserCountry} = {
            'Austria'       => 'Austria',
            'Belgium'       => 'Belgium',
            'Germany'       => 'Germany',
            'United States' => 'United States',
        };

        $Helper->ConfigSettingChange(
            Key   => 'CustomerUser',
            Value => $CustomerUserConfig,
        );

        my @CustomerCompanyTests = (
            {
                CustomerID             => $RandomNumber . '-test1',
                CustomerCompanyName    => $RandomNumber . ' Test1 Inc',
                CustomerCompanyStreet  => 'Some Street',
                CustomerCompanyZIP     => '12345',
                CustomerCompanyCity    => 'Some city',
                CustomerCompanyCountry => 'Germany',
                CustomerCompanyURL     => 'http://example.com',
                CustomerCompanyComment => 'some comment',
                ValidID                => 1,
                UserID                 => 1,
                DynamicFields          => {
                    $DynamicFieldIDs[5] => '100',
                },
            },
            {
                CustomerID             => $RandomNumber . '-test2',
                CustomerCompanyName    => $RandomNumber . ' Test2 Inc',
                CustomerCompanyStreet  => 'Some Street',
                CustomerCompanyZIP     => '12345',
                CustomerCompanyCity    => 'Some city',
                CustomerCompanyCountry => 'Germany',
                CustomerCompanyURL     => 'http://example.com',
                CustomerCompanyComment => 'some comment',
                ValidID                => 1,
                UserID                 => 1,
                DynamicFields          => {
                    $DynamicFieldIDs[5] => '200',
                },
            },
        );

        my @CustomerCompanies;

        for my $CustomerCompany (@CustomerCompanyTests) {

            my $CustomerCompanyID = $CustomerCompanyObject->CustomerCompanyAdd(
                %{$CustomerCompany}
            );

            push @CustomerCompanies, $CustomerCompanyID;

            $Self->True(
                $CustomerCompanyID,
                "CustomerCompanyAdd() - $CustomerCompanyID",
            );

            if ( IsHashRefWithData( $CustomerCompany->{DynamicFields} ) ) {

                for my $DynamicFieldID ( sort keys %{ $CustomerCompany->{DynamicFields} } ) {

                    my $DynamicFieldConfig = $DynamicFieldObject->DynamicFieldGet(
                        ID => $DynamicFieldID,
                    );

                    $DynamicFieldBackendObject->ValueSet(
                        DynamicFieldConfig => $DynamicFieldConfig,
                        ObjectName         => $CustomerCompanyID,
                        Value              => $CustomerCompany->{DynamicFields}->{$DynamicFieldID},
                        UserID             => 1,
                    );
                }
            }
        }

        my @CustomerUserTests = (
            {
                Source         => 'CustomerUser',
                UserFirstname  => 'Firstname Test1',
                UserLastname   => 'Lastname Test1',
                UserCustomerID => $CustomerCompanies[0],
                UserLogin      => $RandomNumber . '-1',
                UserEmail      => $RandomNumber . '-1-Email@example.com',
                UserPassword   => 'some_pass',
                UserTitle      => 'Mr.',
                UserCountry    => 'Germany',
                ValidID        => 1,
                UserID         => 1,
                DynamicFields  => {
                    $DynamicFieldIDs[0] => 'Example text 1234',
                    $DynamicFieldIDs[1] => 1,
                    $DynamicFieldIDs[2] => [ 'a', ],
                },
            },
            {
                Source         => 'CustomerUser',
                UserFirstname  => 'Firstname Test2',
                UserLastname   => 'Lastname Test2',
                UserCustomerID => $CustomerCompanies[0],
                UserLogin      => $RandomNumber . '-2',
                UserEmail      => $RandomNumber . '-2-Email@example.com',
                UserPassword   => 'some_pass',
                UserTitle      => 'Mrs.',
                UserCountry    => 'Austria',
                ValidID        => 1,
                UserID         => 1,
                DynamicFields  => {
                    $DynamicFieldIDs[0] => 'Example text',
                    $DynamicFieldIDs[1] => 1,
                    $DynamicFieldIDs[2] => [ 'a', 'd' ],
                },
            },
            {
                Source         => 'CustomerUser',
                UserFirstname  => 'Firstname Test3',
                UserLastname   => 'Lastname Test3',
                UserCustomerID => $CustomerCompanies[1],
                UserLogin      => $RandomNumber . '-3',
                UserEmail      => $RandomNumber . '-3-Email@example.com',
                UserPassword   => 'some_pass',
                UserTitle      => 'Mrs.',
                UserCountry    => 'Germany',
                ValidID        => 1,
                UserID         => 1,
                DynamicFields  => {
                    $DynamicFieldIDs[2] => [ 'a', 'b' ],
                },
            },
            {
                Source         => 'CustomerUser',
                UserFirstname  => 'John Test4',
                UserLastname   => 'Doe Test4',
                UserCustomerID => $CustomerCompanies[1],
                UserLogin      => $RandomNumber . '-4',
                UserEmail      => $RandomNumber . '-4-Email@example.com',
                UserPassword   => 'some_pass',
                UserTitle      => 'Mr.',
                UserCountry    => 'United States',
                ValidID        => 1,
                UserID         => 1,
            },
        );

        my @CustomerUserLogins;
        my %CustomerUserMailStrings;

        for my $CustomerUser (@CustomerUserTests) {

            my $UserLogin = $CustomerUserObject->CustomerUserAdd(
                %{$CustomerUser}
            );

            push @CustomerUserLogins, $UserLogin;

            $Self->True(
                $UserLogin,
                "CustomerUserAdd() - $UserLogin",
            );

            if ( IsHashRefWithData( $CustomerUser->{DynamicFields} ) ) {

                for my $DynamicFieldID ( sort keys %{ $CustomerUser->{DynamicFields} } ) {

                    my $DynamicFieldConfig = $DynamicFieldObject->DynamicFieldGet(
                        ID => $DynamicFieldID,
                    );

                    $DynamicFieldBackendObject->ValueSet(
                        DynamicFieldConfig => $DynamicFieldConfig,
                        ObjectName         => $UserLogin,
                        Value              => $CustomerUser->{DynamicFields}->{$DynamicFieldID},
                        UserID             => 1,
                    );
                }
            }

            my %CustomerUserData = $CustomerUserObject->CustomerUserDataGet(
                User => $UserLogin,
            );

            $CustomerUserMailStrings{$UserLogin} = $CustomerUserData{UserMailString};
        }

        my $TestUserLogin = $Helper->TestUserCreate(
            Groups => [ 'admin', 'users' ],
        ) || die "Did not get test user";

        $Selenium->Login(
            Type     => 'Agent',
            User     => $TestUserLogin,
            Password => $TestUserLogin,
        );

        my $ScriptAlias = $Kernel::OM->Get('Kernel::Config')->Get('ScriptAlias');

        my @Tests = (
            [
                # Find all customer user
                {
                    RecipientField     => 'ToCustomer',
                    CheckDefaultFields => 1,
                    SearchParameter    => {
                        Input => {
                            UserLogin => '*',
                        },
                    },
                    SearchResultCustomerUser => \@CustomerUserLogins,
                    SelectRecipient          => \@CustomerUserLogins,
                },
            ],
            [
                # Find all customer user
                {
                    RecipientField     => 'CcCustomer',
                    CheckDefaultFields => 1,
                    SearchParameter    => {
                        Input => {
                            UserLogin => '*',
                        },
                    },
                    SearchResultCustomerUser => \@CustomerUserLogins,
                    SelectRecipient          => \@CustomerUserLogins,
                },
            ],
            [
                # Find all customer user
                {
                    RecipientField     => 'BccCustomer',
                    CheckDefaultFields => 1,
                    SearchParameter    => {
                        Input => {
                            UserLogin => '*',
                        },
                    },
                    SearchResultCustomerUser => \@CustomerUserLogins,
                    SelectRecipient          => \@CustomerUserLogins,
                },
            ],
            [
                {
                    RecipientField      => 'ToCustomer',
                    RemoveDefaultFields => 1,
                    SearchFieldsAdd     => [
                        'UserCountry',
                        'UserTitle',
                    ],
                    SearchParameter => {
                        Selection => {
                            UserTitle   => 'Mr.',
                            UserCountry => 'Germany',
                        },
                    },
                    SearchResultCustomerUser => [ $CustomerUserLogins[0] ],
                    SelectRecipient          => [ $CustomerUserLogins[0] ],
                },
                {
                    RecipientField      => 'CcCustomer',
                    RemoveDefaultFields => 1,
                    SearchFieldsAdd     => [
                        'Search_' . $DynamicFieldCustomerUserSearchFields[0],
                        'Search_' . $DynamicFieldCustomerUserSearchFields[1],
                    ],
                    SearchParameter => {
                        Input => {
                            'Search_' . $DynamicFieldCustomerUserSearchFields[0] => 'Example*',
                        },
                        Selection => {
                            'Search_' . $DynamicFieldCustomerUserSearchFields[1] => 1,
                        },
                    },
                    ExcludeSearchResultCustomerUser => [ $CustomerUserLogins[0] ],
                    SearchResultCustomerUser        => [ $CustomerUserLogins[1] ],
                    SelectRecipient                 => [ $CustomerUserLogins[1] ],
                },
                {
                    RecipientField      => 'BccCustomer',
                    RemoveDefaultFields => 1,
                    SearchFieldsAdd     => [
                        'Search_' . $DynamicFieldCustomerUserSearchFields[2],
                    ],
                    SearchParameter => {
                        Selection => {
                            'Search_' . $DynamicFieldCustomerUserSearchFields[2] => 'a',
                        },
                    },
                    ExcludeSearchResultCustomerUser => [ $CustomerUserLogins[0], $CustomerUserLogins[1] ],
                    SearchResultCustomerUser        => [ $CustomerUserLogins[2] ],
                    SelectRecipient                 => [ $CustomerUserLogins[2] ],
                },
            ],
            [
                {
                    RecipientField      => 'ToCustomer',
                    RemoveDefaultFields => 1,
                    SearchFieldsAdd     => [
                        'Search_' . $DynamicFieldCustomerCompanySearchFields[0],
                    ],
                    SearchParameter => {
                        Selection => {
                            'Search_' . $DynamicFieldCustomerCompanySearchFields[0] => [ '100', '200', ],
                        },
                    },
                    SearchResultCustomerUser => \@CustomerUserLogins,
                    SelectAllRecipient       => 1,
                },
            ],
            [
                {
                    RemoveSelectedRecipient => 1,
                    RecipientField          => 'ToCustomer',
                    RemoveDefaultFields     => 1,
                    SearchFieldsAdd         => [
                        'Search_' . $DynamicFieldCustomerCompanySearchFields[0],
                    ],
                    SearchParameter => {
                        Selection => {
                            'Search_' . $DynamicFieldCustomerCompanySearchFields[0] => [ '100', '200', ],
                        },
                    },
                    SearchResultCustomerUser => \@CustomerUserLogins,
                    SearchFieldsChange       => [
                        'Search_' . $DynamicFieldCustomerUserSearchFields[2],
                    ],
                    SearchParameterChange => {
                        Selection => {
                            'Search_' . $DynamicFieldCustomerCompanySearchFields[0] => [ '100', ],
                            'Search_' . $DynamicFieldCustomerUserSearchFields[2]    => 'd',
                        },
                    },
                    ExcludeSearchResultChangeCustomerUser =>
                        [ $CustomerUserLogins[0], $CustomerUserLogins[2], $CustomerUserLogins[3], ],
                    SearchResultChangeCustomerUser => [ $CustomerUserLogins[1], ],
                },
            ],
            [
                # Check the alert message, if no search parameter is present.
                {
                    RecipientField        => 'ToCustomer',
                    CheckDefaultFields    => 1,
                    SearchParameter       => {},
                    SearchParameterChange => {
                        Input => {
                            UserLogin => "$RandomNumber*",
                        },
                    },
                    SearchResultChangeCustomerUser => \@CustomerUserLogins,
                },
            ],
            [
                # Add a search profile and use it again.
                {
                    RecipientField  => 'ToCustomer',
                    SearchParameter => {
                        Input => {
                            UserLogin => "$RandomNumber*",
                        },
                        CreateSearchProfile => "Alles$RandomNumber",
                    },
                    SearchResultCustomerUser => \@CustomerUserLogins,
                    SelectRecipient          => \@CustomerUserLogins,
                },
                {
                    RecipientField                  => 'ToCustomer',
                    UseSearchProfile                => "Alles$RandomNumber",
                    ExcludeSearchResultCustomerUser => \@CustomerUserLogins,
                },
            ],
        );

        my $AgentCustomerUserAddressBookConfig
            = $ConfigObject->Get("CustomerUser::Frontend::AgentCustomerUserAddressBook");

        for my $Test (@Tests) {

            # Reload the AgentTicketEmail screen for every test, to refresh the page completely.
            $Selenium->VerifiedGet("${ScriptAlias}index.pl?Action=AgentTicketEmail");

            for my $SubTest ( @{$Test} ) {

                $Selenium->find_element( "#OptionCustomerUserAddressBook" . $SubTest->{RecipientField}, 'css' )
                    ->VerifiedClick();
                $Selenium->switch_to_frame( $Selenium->find_element( '.CustomerUserAddressBook', 'css' ) );

                $Selenium->WaitFor(
                    JavaScript =>
                        'return typeof(Core) == "object" && typeof(Core.App) == "object" && Core.App.PageLoadComplete'
                );

                # Check the default fields for the initial address book screen.
                if ( $SubTest->{CheckDefaultFields} ) {

                    for my $ID (qw(SearchProfile SearchProfileNew Attribute)) {
                        my $Element = $Selenium->find_element( "#$ID", 'css' );
                        $Element->is_enabled();
                        $Element->is_displayed();
                    }

                    for my $FieldName ( @{ $AgentCustomerUserAddressBookConfig->{DefaultFields}->{Email} } ) {
                        my $Element = $Selenium->find_element( $FieldName, 'name' );
                        $Element->is_enabled();
                        $Element->is_displayed();
                    }
                }

                # Check the default fields for the initial address book screen.
                if ( $SubTest->{RemoveDefaultFields} ) {

                    for my $FieldName ( @{ $AgentCustomerUserAddressBookConfig->{DefaultFields}->{Email} } ) {

                        $Selenium->find_element( "input[name='$FieldName'] + .RemoveButton", 'css' )->click();

                        $Self->False(
                            $Selenium->find_element( $FieldName, 'name' )->is_displayed(),
                            "Field '$FieldName' is not displayed'"
                        );
                    }
                }

                if ( IsArrayRefWithData( $SubTest->{SearchFieldsAdd} ) ) {

                    for my $FieldName ( @{ $SubTest->{SearchFieldsAdd} } ) {

                        $Selenium->execute_script(
                            "\$('#Attribute').val('$FieldName').trigger('redraw.InputField').trigger('change');",
                        );
                        $Selenium->find_element( '.AddButton', 'css' )->click();

                        my $Element = $Selenium->find_element( $FieldName, 'name' );
                        $Element->is_enabled();
                        $Element->is_displayed();
                    }
                }

                if ( IsHashRefWithData( $SubTest->{SearchParameter} ) ) {

                    for my $FieldName ( sort keys %{ $SubTest->{SearchParameter}->{Input} } ) {
                        $Selenium->find_element( $FieldName, 'name' )
                            ->send_keys( $SubTest->{SearchParameter}->{Input}->{$FieldName} );
                    }

                    for my $FieldName ( sort keys %{ $SubTest->{SearchParameter}->{Selection} } ) {

                        if ( IsArrayRefWithData( $SubTest->{SearchParameter}->{Selection}->{$FieldName} ) ) {

                            my $ValuesString = $Kernel::OM->Get('Kernel::System::JSON')->Encode(
                                Data => $SubTest->{SearchParameter}->{Selection}->{$FieldName},
                            );

                            $Selenium->execute_script(
                                "\$('select[name=\"$FieldName\"]').val($ValuesString).trigger('redraw.InputField').trigger('change');",
                            );
                        }
                        else {
                            $Selenium->execute_script(
                                "\$('select[name=\"$FieldName\"]').val('$SubTest->{SearchParameter}->{Selection}->{$FieldName}').trigger('redraw.InputField').trigger('change');",
                            );
                        }
                    }

                    # Create a search profile for the search parameters
                    if ( $SubTest->{SearchParameter}->{CreateSearchProfile} ) {

                        $Selenium->find_element( '#SearchProfileNew',     'css' )->click();
                        $Selenium->find_element( '#SearchProfileAddName', 'css' )
                            ->send_keys( $SubTest->{SearchParameter}->{CreateSearchProfile} );
                        $Selenium->find_element( '#SearchProfileAddAction', 'css' )->click();
                    }

              # Switch to the "main" window to click the search submit button and switch back to the address book frame.
                    $Selenium->switch_to_frame();
                    $Selenium->find_element( '#SearchFormSubmit', 'css' )->click();
                    $Selenium->switch_to_frame( $Selenium->find_element( '.CustomerUserAddressBook', 'css' ) );

                    $Selenium->WaitFor(
                        JavaScript =>
                            'return typeof(Core) == "object" && typeof(Core.App) == "object" && Core.App.PageLoadComplete'
                    );
                }
                elsif ( $SubTest->{UseSearchProfile} ) {

                    $Selenium->execute_script(
                        "\$('#SearchProfile').val('$SubTest->{UseSearchProfile}').trigger('change');",
                    );

                    # wait until form and overlay has loaded, if neccessary
                    $Selenium->WaitFor( JavaScript => "return typeof(\$) === 'function' && \$('#SaveProfile').length" );

              # Switch to the "main" window to click the search submit button and switch back to the address book frame.
                    $Selenium->switch_to_frame();
                    $Selenium->find_element( '#SearchFormSubmit', 'css' )->click();
                    $Selenium->switch_to_frame( $Selenium->find_element( '.CustomerUserAddressBook', 'css' ) );

                    $Selenium->WaitFor(
                        JavaScript =>
                            'return typeof(Core) == "object" && typeof(Core.App) == "object" && Core.App.PageLoadComplete'
                    );
                }
                else {

              # Switch to the "main" window to click the search submit button and switch back to the address book frame.
                    $Selenium->switch_to_frame();
                    $Selenium->find_element( '#SearchFormSubmit', 'css' )->click();

                    $Selenium->WaitFor( AlertPresent => 1 ) || die 'Alert for SearchValue not found';

                    $Self->Is(
                        $Selenium->get_alert_text(),
                        'Please enter at least one search value or * to find anything.',
                        'Alert string is found',
                    );

                    # accept alert
                    $Selenium->accept_alert();

                    $Selenium->switch_to_frame( $Selenium->find_element( '.CustomerUserAddressBook', 'css' ) );

                    $Selenium->WaitFor(
                        JavaScript =>
                            'return typeof(Core) == "object" && typeof(Core.App) == "object" && Core.App.PageLoadComplete'
                    );
                }

                if ( IsArrayRefWithData( $SubTest->{ExcludeSearchResultCustomerUser} ) ) {

                    for my $CustomerUserLogin ( @{ $SubTest->{ExcludeSearchResultCustomerUser} } ) {

                        $Self->True(
                            $Selenium->execute_script(
                                "return \$('input[value=\"$CustomerUserLogin\"]:disabled').length;"),
                            "CustomerUser $CustomerUserLogin is disabled on result page",
                        );
                    }
                }

                if ( IsArrayRefWithData( $SubTest->{SearchResultCustomerUser} ) ) {

                    for my $CustomerUserLogin ( @{ $SubTest->{SearchResultCustomerUser} } ) {
                        $Self->True(
                            index( $Selenium->get_page_source(), $CustomerUserLogin ) > -1,
                            "CustomerUser $CustomerUserLogin found on result page",
                        );
                    }
                }

                if ( IsArrayRefWithData( $SubTest->{SearchFieldsChange} ) ) {

                    # Go only back, if the search was executed before, otherwise the correct page is already present.
                    if ( IsHashRefWithData( $SubTest->{SearchParameter} ) ) {
                        $Selenium->find_element( '#ChangeSearch', 'css' )->click();
                    }

                    $Selenium->WaitFor(
                        JavaScript =>
                            'return typeof(Core) == "object" && typeof(Core.App) == "object" && Core.App.PageLoadComplete'
                    );

                    for my $FieldName ( @{ $SubTest->{SearchFieldsChange} } ) {

                        $Selenium->execute_script(
                            "\$('#Attribute').val('$FieldName').trigger('redraw.InputField').trigger('change');",
                        );
                        $Selenium->find_element( '.AddButton', 'css' )->click();

                        my $Element = $Selenium->find_element( $FieldName, 'name' );
                        $Element->is_enabled();
                        $Element->is_displayed();
                    }
                }

                if ( IsHashRefWithData( $SubTest->{SearchParameterChange} ) ) {

                    for my $FieldName ( sort keys %{ $SubTest->{SearchParameterChange}->{Input} } ) {
                        $Selenium->find_element( $FieldName, 'name' )
                            ->send_keys( $SubTest->{SearchParameterChange}->{Input}->{$FieldName} );
                    }

                    for my $FieldName ( sort keys %{ $SubTest->{SearchParameterChange}->{Selection} } ) {

                        if ( IsArrayRefWithData( $SubTest->{SearchParameterChange}->{Selection}->{$FieldName} ) ) {

                            my $ValuesString = $Kernel::OM->Get('Kernel::System::JSON')->Encode(
                                Data => $SubTest->{SearchParameterChange}->{Selection}->{$FieldName},
                            );

                            $Selenium->execute_script(
                                "\$('select[name=\"$FieldName\"]').val($ValuesString).trigger('redraw.InputField').trigger('change');",
                            );
                        }
                        else {
                            $Selenium->execute_script(
                                "\$('select[name=\"$FieldName\"]').val('$SubTest->{SearchParameterChange}->{Selection}->{$FieldName}').trigger('redraw.InputField').trigger('change');",
                            );
                        }
                    }

              # Switch to the "main" window to click the search submit button and switch back to the address book frame.
                    $Selenium->switch_to_frame();
                    $Selenium->find_element( '#SearchFormSubmit', 'css' )->click();
                    $Selenium->switch_to_frame( $Selenium->find_element( '.CustomerUserAddressBook', 'css' ) );

                    $Selenium->WaitFor(
                        JavaScript =>
                            'return typeof(Core) == "object" && typeof(Core.App) == "object" && Core.App.PageLoadComplete'
                    );
                }

                if ( IsArrayRefWithData( $SubTest->{ExcludeSearchResultChangeCustomerUser} ) ) {

                    for my $CustomerUserLogin ( @{ $SubTest->{ExcludeSearchResultChangeCustomerUser} } ) {
                        $Self->True(
                            index( $Selenium->get_page_source(), $CustomerUserLogin ) == -1,
                            "CustomerUser $CustomerUserLogin not found on result page",
                        );
                    }
                }

                if ( IsArrayRefWithData( $SubTest->{SearchResultChangeCustomerUser} ) ) {

                    for my $CustomerUserLogin ( @{ $SubTest->{SearchResultChangeCustomerUser} } ) {
                        $Self->True(
                            index( $Selenium->get_page_source(), $CustomerUserLogin ) > -1,
                            "CustomerUser $CustomerUserLogin found on result page",
                        );
                    }
                }

                if ( IsArrayRefWithData( $SubTest->{SelectRecipient} ) ) {

                    for my $CustomerUserLogin ( @{ $SubTest->{SelectRecipient} } ) {
                        $Selenium->find_element("//input[\@value='$CustomerUserLogin']")->click();
                    }

                    $Selenium->WaitFor(
                        JavaScript => 'return typeof($) === "function" && $("#RecipientSelect", parent.document).length'
                    );

                    $Selenium->switch_to_frame();
                    $Selenium->find_element( '#RecipientSelect', 'css' )->click();

                    my $Handles = $Selenium->get_window_handles();
                    $Selenium->switch_to_window( $Handles->[0] );

                    # Wait until form is updated with the selected customer user.
                    $Selenium->WaitFor(
                        JavaScript =>
                            'return typeof($) === "function" && $("#TicketCustomerContent'
                            . $SubTest->{RecipientField}
                            . ':visible").length'
                    );

                    # Wait for ajax call after customer user selection.
                    $Selenium->WaitFor(
                        JavaScript => 'return typeof($) === "function" && !$("span.AJAXLoader:visible").length'
                    );

                    for my $CustomerUserLogin ( @{ $SubTest->{SelectRecipient} } ) {
                        $Self->True(
                            index( $Selenium->get_page_source(), $CustomerUserLogin ) > -1,
                            "CustomerUser mail $CustomerUserMailStrings{$CustomerUserLogin} found on ticket email page",
                        );
                    }
                }

                if ( $SubTest->{SelectAllRecipient} ) {
                    $Selenium->find_element( '#SelectAllCustomerUser', 'css' )->click();

                    $Selenium->WaitFor(
                        JavaScript => 'return typeof($) === "function" && $("#RecipientSelect", parent.document).length'
                    );

                    $Selenium->switch_to_frame();
                    $Selenium->find_element( '#RecipientSelect', 'css' )->click();

                    my $Handles = $Selenium->get_window_handles();
                    $Selenium->switch_to_window( $Handles->[0] );

                    # Wait until form is updated with the selected customer user.
                    $Selenium->WaitFor(
                        JavaScript =>
                            'return typeof($) === "function" && $("#TicketCustomerContent'
                            . $SubTest->{RecipientField}
                            . ':visible").length'
                    );

                    # Wait for ajax call after customer user selection.
                    $Selenium->WaitFor(
                        JavaScript => 'return typeof($) === "function" && !$("span.AJAXLoader:visible").length'
                    );

                    for my $CustomerUserLogin ( @{ $SubTest->{SearchResultCustomerUser} } ) {
                        $Self->True(
                            index( $Selenium->get_page_source(), $CustomerUserLogin ) > -1,
                            "CustomerUser mail $CustomerUserMailStrings{$CustomerUserLogin} found on ticket email page",
                        );
                    }
                }
            }
        }

        # Cleanup the created customer user and customer companies.
        my $DBObject                = $Kernel::OM->Get('Kernel::System::DB');
        my $DynamicFieldValueObject = $Kernel::OM->Get('Kernel::System::DynamicFieldValue');

        my $Success;

        for my $DynamicFieldID (@DynamicFieldIDs) {

            $Success = $DynamicFieldValueObject->AllValuesDelete(
                FieldID => $DynamicFieldID,
                UserID  => 1,
            );
            $Self->True(
                $Success,
                "Dynamic field values - ID $DynamicFieldID - deleted",
            );

            $Success = $DynamicFieldObject->DynamicFieldDelete(
                ID     => $DynamicFieldID,
                UserID => 1,
            );
            $Self->True(
                $Success,
                "Dynamic field - ID $DynamicFieldID - deleted",
            );
        }

        for my $CustomerUserLogin (@CustomerUserLogins) {

            $Success = $DBObject->Do(
                SQL  => "DELETE FROM dynamic_field_obj_id_name WHERE object_name = ?",
                Bind => [ \$CustomerUserLogin ],
            );
            $Self->True(
                $Success,
                "CustomerUserID $CustomerUserLogin dynamic field object mapping is deleted",
            );

            $Success = $DBObject->Do(
                SQL  => "DELETE FROM customer_user WHERE login = ?",
                Bind => [ \$CustomerUserLogin ],
            );
            $Self->True(
                $Success,
                "CustomerUserID $CustomerUserLogin is deleted",
            );
        }

        for my $CustomerCompanyID (@CustomerCompanies) {

            $Success = $DBObject->Do(
                SQL  => "DELETE FROM dynamic_field_obj_id_name WHERE object_name = ?",
                Bind => [ \$CustomerCompanyID ],
            );
            $Self->True(
                $Success,
                "CustomerCompanyID $CustomerCompanyID dynamic field object mapping is deleted",
            );

            $Success = $DBObject->Do(
                SQL  => "DELETE FROM customer_company WHERE customer_id = ?",
                Bind => [ \$CustomerCompanyID ],
            );
            $Self->True(
                $Success,
                "CustomerCompanyID $CustomerCompanyID is deleted",
            );
        }

        # Make sure that the cache is correct, because we delete the data directly in the database.
        for my $Cache (qw (CustomerUser CustomerCompany)) {
            $Kernel::OM->Get('Kernel::System::Cache')->CleanUp(
                Type => $Cache,
            );
        }

    }
);

1;
