// exports.functionName = (parameters) => {}

function isInvalidEmail(userObj) {
    return !userObj.email.includes("@")
}

function isEmptyPayload(userObj) {
    return Object.keys(userObj).length === 0
}

module.exports = {
    isInvalidEmail,
    isEmptyPayload
}