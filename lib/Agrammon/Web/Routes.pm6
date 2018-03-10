use v6;

use Cro::HTTP::Router;

use Agrammon::Web::Service;
use Agrammon::Web::UserSession;

### TODO 
#     auth                   => 1,

#     delete_datasets        => 2,
#     send_datasets          => 2,

#     create_dataset         => 2,
#     clone_dataset          => 2,
#     rename_dataset         => 2,
#     submit_dataset         => 2,
#     load_dataset           => 2,

#     get_output_variables   => 2,
#     get_input_variables    => 2,
#     get_input              => 2,

#     store_data             => 2,
#     store_dataset_comment  => 2,
#     store_variable_comment => 2,
#     delete_data            => 2,
#     load_branch_data       => 2,
#     store_branch_data      => 2,

#     set_tag                => 2,
#     remove_tag             => 2,
#     delete_tag             => 2,
#     rename_tag             => 2,
#     new_tag                => 2,

#     rename_instance        => 2,
#     order_instances        => 2,

#     create_account         => 2,
#     reset_password         => 2,
#     change_password        => 2,


sub routes(Agrammon::Web::Service $ws) is export {
    route {
        subset Admin    of Agrammon::Web::UserSession where .is-admin;
        subset LoggedIn of Agrammon::Web::UserSession where *.logged-in;

        get -> 'index.html' {
            static 'static/index.html'
        }

        get -> {
            static 'static/index.html'
        }

        get -> 'agrammon.html' {
            static 'static/agrammon.html'
        }

        get -> 'script', *@path {
            static 'static/script', @path
        }
        
        get -> '/busy.gif' {
            static 'static/busy.gif'
        }

        post -> Agrammon::Web::UserSession $user, 'auth' {
#            request-body -> (:$user, :$password, *%) {
#                my $username = $user;
            request-body -> %data {
                dd %data;
                my $username = %data<user>;
                my $password = %data<password>;
                if $user.auth($username, $password) {
                    $user.username = $username;
                    $user.load($username);
                    content 'application/json', %(
                        user       => $username,
                        role       => $user.role.name,
                        last_login => $user.last-login,
                        news       => 'No news',
                        sudoUser   => 0
                    );
                }
                else {
                }
            }
        }

        post -> 'get_cfg' {
            my $data = $ws.get-cfg;
            content 'application/json', $data;
        }

        post -> LoggedIn $user, 'get_datasets' {
            my $model-version = 'SingleSHL';
            my $data = $ws.get-datasets($user, $model-version);
            content 'application/json', $data;
        }

        post -> LoggedIn $user, 'get_tags' {
            my $data = $ws.get-tags($user);
            content 'application/json', $data;
        }

        get -> LoggedIn $user, 'create-dataset', $name {
            my $data = $ws.create-dataset($user, $name);
            content 'application/json', $data;
        }

        get -> LoggedIn $user, 'create-tag', $name {
            my $data = $ws.create-tag($user, $name);
            content 'application/json', $data;
        }

    }
}
