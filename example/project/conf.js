exports.config = {
    directConnect: true,
    specs: ["./spec.js"],
    capabilities: {
        browserName: 'chrome',
        marionette: true,
        acceptInsecureCerts: true,
        chromeOptions: {
            args: ['--no-sandbox']
        }
    },
};
