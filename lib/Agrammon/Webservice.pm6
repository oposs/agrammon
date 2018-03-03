use v6;
#use Agrammon::ModuleParser;
#use Agrammon::Model::Module;

#class X::Agrammon::Model::CircularModel is Exception {
#    has $.module;
#    method message() {
#        "Module $!module has circular dependency!";
#    }
#}

class Agrammon::Webservice {
#    has IO::Path $.path;
#    has Agrammon::Model::Module @.evaluation-order;
  
    method get-cfg() {
    }

}
