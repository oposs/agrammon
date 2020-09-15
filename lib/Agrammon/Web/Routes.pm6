use v6;

use Cro::HTTP::Router;

use Agrammon::Web::Service;
use Agrammon::Web::SessionUser;

subset LoggedIn of Agrammon::Web::SessionUser where .logged-in;

sub routes(Agrammon::Web::Service $ws) is export {

    # Fix for Agrammon
    # my $root = $app ~~ Agrammon::Application::Development ?? 'frontend/source-output' !! 'qx-build';
    my $root = '';
    route {
        include static-content($root);
        include user-routes($ws);
        include dataset-routes($ws);
        include application-routes($ws);
        after {
            forbidden if .status == 401 && request.auth.logged-in;
            .status = 401 if .status == 418;
        }
    }
}

sub static-content($root) is export {
    route {
        get -> 'index.html' {
            static $root ~ 'static/index.html'
        }

        get -> {
            static $root ~ 'static/index.html'
        }

        get -> 'agrammon.html' {
            static $root ~ 'static/agrammon.html'
        }

        get -> 'script', *@path {
            static $root ~ 'static/script', @path
        }

        get -> 'source', *@path {
            static $root ~ 'static/source', @path
        }

        get -> 'QxJqPlot/source/resource', *@path {
            static $root ~ 'static/resource', @path
        }

        get -> 'resource', *@path {
            static $root ~ 'static/resource', @path
        }

        get -> 'qooxdoo', *@path {
            static $root ~ 'static/qooxdoo', @path
        }
    }
}

sub dataset-routes(Agrammon::Web::Service $ws) {
    route {
        # working
        post -> LoggedIn $user, 'get_datasets' {
            my $cfg = $ws.cfg;
            my $model-version = $cfg.model-variant; # model 'SingleSHL';

            my $data = $ws.get-datasets($user, $model-version);
            content 'application/json', $data;
        }

        post -> LoggedIn $user, 'delete_datasets' {
            ...
            my $data = $ws.delete-datasets($user);
            content 'application/json', $data;
        }

        post -> LoggedIn $user, 'send_datasets' {
            ...
            my $data = $ws.send-datasets($user);
            content 'application/json', $data;
        }

        ### dataset
        # working/test
        post -> LoggedIn $user, 'create_dataset' {
            request-body -> (:$name!) {
                my $data = $ws.create-dataset($user, $name);
                content 'application/json', $data;
            }
        }

        # implement/test
        post -> LoggedIn $user, 'rename_dataset' {
            request-body -> (:$old!, :$new!) {
                my $data = $ws.rename-dataset($user, $old, $new);
                content 'application/json', $data;
            }
        }

        # implement/test
        post -> LoggedIn $user, 'submit_dataset' {
            request-body -> (:$name!, :$mail) {
                my $data = $ws.submit-dataset($user, $name, $mail);
                content 'application/json', $data;
            }
        }

        # implement/test
        post -> LoggedIn $user, 'load_dataset' {
            request-body -> (:name($dataset)!) {
                say "#### load_dataset(): dataset=$dataset";
                my @data = $ws.load-dataset($user, $dataset);
                content 'application/json', @data;
            }
        }

        # test/implement
        post -> LoggedIn $user, 'store_dataset_comment' {
            request-body -> (:$name!, :$comment!) {
                my $data = $ws.store-dataset-comment($user, $name, $comment);
                content 'application/json', $data;
            }
        }

        ### tags
        post -> LoggedIn $user, 'get_tags' {
            my $data = $ws.get-tags($user);
            content 'application/json', $data;
        }

        # test/implement
        post -> LoggedIn $user, 'create_tag' {
            request-body -> (:$name!) {
                my $data = $ws.create-tag($user, $name);
                content 'application/json', $data;
            }
        }

        # test/implement
        post -> LoggedIn $user, 'set_tag' {
            request-body -> (:@datasets!, :$tag!) {
                my $data = $ws.set-tag($user, @datasets, $tag);
                content 'application/json', $data;
            }
        }

        # test/implement
        post -> LoggedIn $user, 'remove_tag' {
            request-body -> (:@datasets!, :$tag!) {
                my $data = $ws.remove-tag($user, @datasets, $tag);
                content 'application/json', $data;
            }
        }

        # test/implement
        post -> LoggedIn $user, 'delete_tag' {
            request-body -> (:$name!) {
                my $data = $ws.delete-tag($user, $name);
                content 'application/json', $data;
            }
        }

        # test/implement
        post -> LoggedIn $user, 'rename_tag' {
            request-body -> (:$old!, :$new!) {
                my $data = $ws.rename-tag($user, $old, $new);
                content 'application/json', $data;
            }
        }

        # test/implement
        post -> LoggedIn $user, 'new_tag' {
            request-body -> (:$name!) {
                my $data = $ws.create-tag($user, $name);
                content 'application/json', $data;
            }
        }
    }
}

sub user-routes(Agrammon::Web::Service $ws) {
    route {

        # implement/test
        post -> LoggedIn $user, 'change_password' {
            request-body -> (:$old-password!, :$new-password!) {
                my $data = $ws.change-password($old-password, $new-password);
                content 'application/json', $data;
            }
        }

        # implement/test
        post -> LoggedIn $user, 'reset_password' {
            request-body -> (:$email!, :$password!, :$key!) {
                my $data = $ws.reset-password($email, $password, $key);
                content 'application/json', $data;
            }
        }

        # implement/test
        post -> LoggedIn $user, 'create_account' {
            request-body -> %user-data {
                my $data = $ws.create-account($user, %user-data);
                content 'application/json', $data;
            }
        }
    }
}

sub application-routes(Agrammon::Web::Service $ws) {
    route {
        ### auth
        post -> Agrammon::Web::SessionUser $user, 'auth' {
            request-body -> %data {
                my $username = %data<user>;
                my $password = %data<password>;
                if $user.auth($username, $password) {
                    content 'application/json', %(
                        user       => $username,
                        role       => $user.role.name,
                        last_login => $user.last-login,
                        # TODO: news not implemented for the moment
                        news       => Nil,
                        sudoUser   => 0
                    );
                }
                else {
                }
            }
        }

        ### cfg
        post -> 'get_cfg' {
            my %cfg = $ws.get-cfg;
            content 'application/json', %cfg;
        }

        ### input/output

        # # test/implement (is this needed?)
        # post -> LoggedIn $user, 'get_input' {
        #         ...
        #     request-body -> (:$dataset!) {
        #         my $data = $ws.get-input($user, $dataset);
        #         content 'application/json', $data;
        #     }
        # }

        # working/test
        post -> LoggedIn $user, 'get_input_variables' {
            request-body -> (:name($dataset)!) {
                say "get_input_variables(): ### dataset=$dataset";
                my %data = $ws.get-input-variables;
                %data<dataset> = $dataset;
                content 'application/json', %data;
            }
        }

        # working/test
        post -> LoggedIn $user, 'get_output_variables' {
            request-body -> %data {
                my %output = $ws.get-output-variables($user, %data<dataset>);
                content 'application/json', %output;
            }
        }

        ### data
        # working/test
        post -> LoggedIn $user, 'store_data' {
            request-body -> %data {
                my $ret = $ws.store-data($user, %data);
                content 'application/json', %( :$ret );
            }
        }

        # test/implement
        post -> LoggedIn $user, 'store_variable_comment' {
            request-body -> (:$name!, :$comment!) {
                my $data = $ws.store-variable-comment($user, $name, $comment);
                content 'application/json', $data;
            }
        }

        # test/implement
        post -> LoggedIn $user, 'delete_data' {
            request-body -> (:$name!) {
                my $data = $ws.delete-data($user, $name);
                content 'application/json', $data;
            }
        }

        # test/implement
        post -> LoggedIn $user, 'load_branch_data' {
            request-body -> (:$name!) {
                my $data = $ws.load-branch-data($user, $name);
                content 'application/json', $data;
            }
        }

        # test/implement
        post -> LoggedIn $user, 'store_branch_data' {
            request-body -> (:%data!, :$dataset-name!) {
                my $data = $ws.store-branch-data($user, %data, $dataset-name);
                content 'application/json', $data;
            }
        }

        # test/implement
        post -> LoggedIn $user, 'rename_instance' {
            request-body -> (:$old!, :$new!) {
                my $data = $ws.rename-instance($user, $old, $new);
                content 'application/json', $data;
            }
        }

        # test/implement
        post -> LoggedIn $user, 'order_instances' {
            request-body -> (:@instances, :$dataset-name!) {
                my $data = $ws.order-instances($user, @instances, $dataset-name);
                content 'application/json', $data;
            }
        }

    }
}
