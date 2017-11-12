
function setPassword(password) {
    return function (inputNode) {
        inputNode.value = password;
    }
}

/*
 * Javascript files used for action processing are expected to
 * define a global variable of ExtensionPreprocessingJS that can
 * have two methods/functions:
 *
 * - run: executed by the action extension when it wants to get data from the webpage
 * - finalize: executed by the action extension when it completes its activity
 */
var ExtensionPreprocessingJS = {
    /*
     * When an action is initialized it can ask to run this script
     * to provide context to the action
     */
    run: function(arguments) {
        // provide the current URI
        // the share extension can use this information to
        // highlight what it thinks is the correct password
        arguments.completionFunction({
            baseURI: document.baseURI
        });
    },
    /*
     * Called when the action has completed picking a password
     */
    finalize: function(arguments) {
        // usually OTP fields are type=tel, but we can't assume this is the case
        // as a fallback, the extension should copy the password to the clipboard
        // as well
        const potentialFields = document.querySelectorAll( 'input[type=text],input[type=tel]' );
        // Use the Array forEach iterator to set the input's value to
        // the provided password
        [].forEach.call(potentialFields, setPassword(arguments.password))
    }
};

