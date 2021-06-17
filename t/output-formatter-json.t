use v6;
use Agrammon::Model;
use Agrammon::OutputFormatter::JSON;
use Test;
use JSON::Fast;

my $path = $*PROGRAM.parent.add('test-data/Models/run-test-multi-deep');
my $model = Agrammon::Model.new(:$path);
$model.load('Test');

my $outputs = Agrammon::Outputs.new;
$outputs.add-output('Test', 'result', 142);
$outputs.declare-multi-instance('Test::SubModule');
given $outputs.new-instance('Test::SubModule', 'Monkey A') {
    .add-output('Test::SubModule', 'sub_result', 20);
    .add-output('Test::SubModule::SubTest', 'kids', 5);
}
given $outputs.new-instance('Test::SubModule', 'Monkey B') {
    .add-output('Test::SubModule', 'sub_result', 30);
    .add-output('Test::SubModule::SubTest', 'kids', 10);
}
given $outputs.new-instance('Test::SubModule', 'Monkey C') {
    .add-output('Test::SubModule', 'sub_result', 40);
    .add-output('Test::SubModule::SubTest', 'kids', 15);
}

my $include-filters = False;
my @print-set = <All>;
my $json= output-as-json($model, $outputs, "en", @print-set, $include-filters);
my $gui= output-for-gui($model, $outputs, :language("en"), :$include-filters);
is to-json($json, :sorted-keys) ~ "\n", q:to/OUTPUT/, "Correct JSON output";
[
  {
    "filters": [
    ],
    "format": "",
    "fullValue": 142,
    "label": null,
    "order": -1,
    "print": "7,All",
    "unit": "monkeys/hour",
    "value": 142,
    "var": "Test::result"
  },
  {
    "filters": [
    ],
    "format": "",
    "fullValue": 20,
    "instance": "Monkey A",
    "label": null,
    "order": -1,
    "print": "7,All",
    "unit": "monkeys/hour",
    "value": 20,
    "var": "Test::SubModule[Monkey A]::sub_result"
  },
  {
    "filters": [
    ],
    "format": "",
    "fullValue": 5,
    "instance": "Monkey A",
    "label": null,
    "order": -1,
    "print": "7,All",
    "unit": "monkey kids",
    "value": 5,
    "var": "Test::SubModule[Monkey A]::SubTest::kids"
  },
  {
    "filters": [
    ],
    "format": "",
    "fullValue": 30,
    "instance": "Monkey B",
    "label": null,
    "order": -1,
    "print": "7,All",
    "unit": "monkeys/hour",
    "value": 30,
    "var": "Test::SubModule[Monkey B]::sub_result"
  },
  {
    "filters": [
    ],
    "format": "",
    "fullValue": 10,
    "instance": "Monkey B",
    "label": null,
    "order": -1,
    "print": "7,All",
    "unit": "monkey kids",
    "value": 10,
    "var": "Test::SubModule[Monkey B]::SubTest::kids"
  },
  {
    "filters": [
    ],
    "format": "",
    "fullValue": 40,
    "instance": "Monkey C",
    "label": null,
    "order": -1,
    "print": "7,All",
    "unit": "monkeys/hour",
    "value": 40,
    "var": "Test::SubModule[Monkey C]::sub_result"
  },
  {
    "filters": [
    ],
    "format": "",
    "fullValue": 15,
    "instance": "Monkey C",
    "label": null,
    "order": -1,
    "print": "7,All",
    "unit": "monkey kids",
    "value": 15,
    "var": "Test::SubModule[Monkey C]::SubTest::kids"
  }
]
OUTPUT

is to-json($gui, :sorted-keys) ~ "\n", q:to/OUTPUT/, "Correct output for gui";
{
  "data": [
    {
      "filters": [
      ],
      "format": "",
      "fullValue": 142,
      "label": null,
      "order": -1,
      "print": "7,All",
      "unit": "monkeys/hour",
      "value": 142,
      "var": "Test::result"
    },
    {
      "filters": [
      ],
      "format": "",
      "fullValue": 20,
      "instance": "Monkey A",
      "label": null,
      "order": -1,
      "print": "7,All",
      "unit": "monkeys/hour",
      "value": 20,
      "var": "Test::SubModule[Monkey A]::sub_result"
    },
    {
      "filters": [
      ],
      "format": "",
      "fullValue": 5,
      "instance": "Monkey A",
      "label": null,
      "order": -1,
      "print": "7,All",
      "unit": "monkey kids",
      "value": 5,
      "var": "Test::SubModule[Monkey A]::SubTest::kids"
    },
    {
      "filters": [
      ],
      "format": "",
      "fullValue": 30,
      "instance": "Monkey B",
      "label": null,
      "order": -1,
      "print": "7,All",
      "unit": "monkeys/hour",
      "value": 30,
      "var": "Test::SubModule[Monkey B]::sub_result"
    },
    {
      "filters": [
      ],
      "format": "",
      "fullValue": 10,
      "instance": "Monkey B",
      "label": null,
      "order": -1,
      "print": "7,All",
      "unit": "monkey kids",
      "value": 10,
      "var": "Test::SubModule[Monkey B]::SubTest::kids"
    },
    {
      "filters": [
      ],
      "format": "",
      "fullValue": 40,
      "instance": "Monkey C",
      "label": null,
      "order": -1,
      "print": "7,All",
      "unit": "monkeys/hour",
      "value": 40,
      "var": "Test::SubModule[Monkey C]::sub_result"
    },
    {
      "filters": [
      ],
      "format": "",
      "fullValue": 15,
      "instance": "Monkey C",
      "label": null,
      "order": -1,
      "print": "7,All",
      "unit": "monkey kids",
      "value": 15,
      "var": "Test::SubModule[Monkey C]::SubTest::kids"
    }
  ],
  "log": [
  ]
}
OUTPUT

done-testing;
