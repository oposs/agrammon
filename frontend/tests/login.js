// import process from "process";

// const target = process.env.QX_TARGET;
// if (!target) {
//   throw new Error("Missing QX_TARGET environment variable");
// }

// fixture `Testing eventrecorder demo application`
//   .page `http://127.0.0.1:8080/compiled/${target}/eventrecorder/index.html`;

import { t } from 'testcafe';

export default async function () {
    const { error } = await t.getBrowserConsoleMessages();
    console.log('console=', error);
}


fixture `Testing Agrammon6`
    .page `http://localhost:20000`;

test('Test Agrammon Login', async t => {
    await t.wait(2000);

    await t.eval(()=>{
        qx.core.Assert.assertTrue(qx.core.Id.getQxObject("Login").isVisible(),"Failed: Login Window is not visible.");
        qx.core.Id.getQxObject("Login/HelpButton").fireEvent("execute");
        qx.core.Assert.assertTrue(qx.core.Id.getQxObject("Login/HelpWindow").isVisible(),"Failed: Login/HelpWindow is not visible.");
    });
//    await t.wait(500);

    await t.eval(()=>{
        qx.core.Id.getQxObject("Login/HelpWindow/CloseButton").fireEvent("execute");
    });
//    await t.wait(500);

    await t.eval(()=>{
        qx.core.Assert.assertFalse(qx.core.Id.getQxObject("Login/HelpWindow").isVisible(),"Failed: Login/HelpWindow is not closed.");
    });

    await t.eval(()=>{
        qx.core.Id.getQxObject("Login/Username").setValue('fritz.zaucker@oetiker.ch');
        qx.core.Id.getQxObject("Login/Password").setValue('test12');
        qx.core.Assert.assertEquals(qx.core.Id.getQxObject("Login/Username").getValue(), 'fritz.zaucker@oetiker.ch', 'Username is wrong' );
        qx.core.Assert.assertEquals(qx.core.Id.getQxObject("Login/Password").getValue(), 'test12', 'Password is wrong');
    });
//    await t.wait(500);

    await t.eval(()=>{
        qx.core.Id.getQxObject("Login/LoginButton").fireEvent("execute");
    });
    await t.wait(500);

    await t.eval(()=>{
        qx.core.Assert.assertFalse(qx.core.Id.getQxObject("Login").isVisible(),"Failed: Login Window is not visible.");
        qx.core.Assert.assertTrue(qx.core.Id.getQxObject("Datasets").isVisible(),"Failed: DatasetTool is not visible.");
        qx.core.Id.getQxObject("Datasets/CloseButton").fireEvent("execute");
    });
    await t.wait(500);

    await t.eval(()=>{
        qx.core.Assert.assertFalse(qx.core.Id.getQxObject("Datasets").isVisible(),"Failed: DatasetTool is not closed.");
        // must be opened to create LogoutButtonID
        qx.core.Id.getQxObject("Menu/File").open();
//        qx.core.Id.getQxObject("Menu/File").close(); doesn't exist
//        qx.core.Id.getQxObject("Menu/FileButton").fireEvent('execute');
//        qx.core.Id.getQxObject("Menu/FileButton").fireEvent('click');
    });
    await t.wait(500);

    await t.eval(()=>{
        qx.core.Assert.assertTrue(qx.core.Id.getQxObject("Menu/File").isVisible(),"Failed: FileMenu is visible.");
//        qx.core.Assert.assertTrue(qx.core.Id.getQxObject("Menu/File/LogoutButton").isVisible(),"Failed: LogoutButton is visible.");
    });
//    await t.wait(500);

//    await t.eval(()=>{
//    });
//    await t.wait(500);

    await t.eval(()=>{
        let btn = qx.core.Id.getQxObject("Menu/File/LogoutButton");
        qx.core.Assert.assertEquals(qx.core.Id.getAbsoluteIdOf(btn), "Menu/File/LogoutButton", "Failed: found LogoutButton");
        console.log('btn=', btn);
        btn.fireEvent('execute');
        qx.core.Id.getQxObject("Menu/FileButton").fireEvent('tap');
    });
    await t.wait(500);

    await t.eval(()=>{
        qx.core.Assert.assertFalse(qx.core.Id.getQxObject("Menu/File").isVisible(),"Failed: FileMenu is closed.");
    });
    await t.wait(500);

    await t.eval(()=>{
        qx.core.Assert.assertTrue(qx.core.Id.getQxObject("Login").isVisible(),"Failed: Login Window is visible.");
    });
//    await t.wait(1500);

});
