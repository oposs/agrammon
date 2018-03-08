use v6;
use JSON::Fast;
use Cro::HTTP::Router;

use Agrammon::Webservice;

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


sub routes() is export {
    my $ws = Agrammon::Webservice.new;
    
    route {
        get -> {
            content 'text/html', "<h1> agrammon </h1>";
        }

        get -> 'get-cfg' {
            my $data = $ws.get-cfg;
            content 'application/json', $data;
        }

        get -> 'get-datasets' {
            my $data = $ws.get-datasets;
            content 'application/json', $data;
        }

        get -> 'get-tags' {
            my $data = $ws.get-tags;
            content 'application/json', $data;
        }

        
    }
}
