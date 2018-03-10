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

        get -> Agrammon::Web::UserSession $s {
            content 'text/html', "Current user: {$s.logged-in ?? $s.username !! '-'}";
        }


        get -> {
            static 'static/index.html'
        }

        get -> 'login' {
            content 'text/html', q:to/HTML/;
            <form method="POST" action="/login">
              <div>
                Username: <input type="text" name="username" />
              </div>
              <div>
                Password: <input type="password" name="password" />
              </div>
              <input type="submit" value="Log In" />
            </form>
            HTML
        }

        post -> Agrammon::Web::UserSession $user, 'login' {
            request-body -> (:$username, :$password, *%) {
                if valid-user-pass($username, $password) {
                    $user.username = $username;
                    redirect '/', :see-other;
                }
                else {
                    content 'text/html', "Bad username/password";
                }
            }
        }

        sub valid-user-pass($username, $password) {
            # Call a database or similar here
            return $username eq 'fritz.zaucker@oetiker.ch' && $password eq 'Wlaschek';
        }

        get -> 'get-cfg' {
            my $data = $ws.get-cfg;
            content 'application/json', $data;
        }

        get -> LoggedIn $user, 'get-datasets', $model-version {
            my $data = $ws.get-datasets($user, $model-version);
            content 'application/json', $data;
        }

        get -> LoggedIn $user, 'users-only' {
            content 'text/html', "Secret page just for *YOU*, $user.username()";
        }

        get -> LoggedIn $user, 'create-dataset', $name {
            my $data = $ws.create-dataset($user, $name);
            content 'application/json', $data;
        }
        
        get -> LoggedIn $user, 'create-tag', $name {
            my $data = $ws.create-tag($user, $name);
            content 'application/json', $data;
        }
        
        get -> LoggedIn $user, 'get-tags' {
            my $data = $ws.get-tags($user);
            content 'application/json', $data;
        }
        
    }
}
