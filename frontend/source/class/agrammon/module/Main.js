/* ************************************************************************

************************************************************************ */

qx.Class.define('agrammon.module.Main',
{
    extend: qx.ui.tabview.TabView,

    construct: function (input, output, reference) {
        this.base(arguments);

        this.__input = input;

        qx.event.message.Bus.subscribe('agrammon.input.select',
                                        this.__selectInput, this);
        this.set({padding:0});

        var report = new agrammon.module.output.Reports(output, reference);
        var graph  = new agrammon.module.output.Graphs(output, reference);

        this.add(input);
        this.add(report);
        this.add(graph);

    }, // construct

    members :
    {
        __input: null,

        __selectInput: function() {
            this.setSelection([this.__input]);
        }
    }
});
