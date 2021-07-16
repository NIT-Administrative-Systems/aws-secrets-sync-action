const core = require('@actions/core');
const { execSync } = require('child_process');
const jsStringEscape = require('js-string-escape');

// Some helpful functions
const containsAll = (arr1, arr2) => arr2.every(arr2Item => arr1.includes(arr2Item))
const sameMembers = (arr1, arr2) => containsAll(arr1, arr2) && containsAll(arr2, arr1);

 // @TODO: add support for secrets & vapor :D
const syncTypes = ['ssm'];

const syncTo = core.getInput('to');
const tfModulePath = core.getInput('tf-module-path');
const awsRegion = core.getInput('region');
const secretValueLookupRaw = core.getInput('secret-values');
let paramResult;

if (! syncTypes.includes(syncTo)) {
    core.setFailed(`Invalid to parameter '${syncTo}' specified.\nSupported sync targets are: ${syncTypes.join(', ')}`);
}

// Stops this from being printed to the log, which would be bad.
core.setSecret(secretValueLookupRaw);
const secretValueLookup = JSON.parse(secretValueLookupRaw);

try {
    /*
    * Disable cli_follow_urlparam, because if a secret's value is a URL,
    * then the aws ssm put-parameter command will try to GET that URL and 
    * use its value as the secret. 
    * 
    * Which is a ridiculous default behaviour.
    */
    execSync('aws configure set cli_follow_urlparam false');
} catch (error) {
    core.setFailed(`Failed to set AWS cli_follow_urlparam to false': ${error.toString()}`);
    return;
}

try {
    paramResult = execSync(`cd ${jsStringEscape(tfModulePath)} && terraform output -json parameters`);
} catch (error) {
    core.setFailed(`Error from terraform output command: ${error.toString()}`);
}

const ssmParamNames = JSON.parse(paramResult.toString());

const ssmKeys = Object.keys(ssmParamNames);
const secretValueKeys = Object.keys(secretValueLookup);
const keysMatch = sameMembers(secretValueKeys, ssmKeys);

if (! keysMatch) {
    core.setFailed(`Failed due to secret key & SSM key mismatch.\nSSM param keys are: ${ssmKeys.join(', ')}\nSecret-values keys are ${secretValueKeys.join(', ')}\nLists should contain the same sets of values. Values are case-sensitive.`);
    return;
}

const toSync = ssmKeys.map((key) => {
    return {
        name: ssmParamNames[key],
        value: secretValueLookup[key],
        region: awsRegion,
    };
});

let successfulSyncs = [];
let syncErrors = [];
for (const ssmParam of toSync) {
    try {
        execSync(`aws ssm put-parameter --name "${jsStringEscape(ssmParam.name)}" --type "SecureString" --value "${jsStringEscape(ssmParam.value)}" --region "${jsStringEscape(ssmParam.region)}" --overwrite`);
        successfulSyncs.push(ssmParam.name);
    } catch (error) {
        syncErrors.push(`Failed to sync ${ssmParam.name} for ${ssmParam.region}: ${error.toString()}`);
    }
}

if (syncErrors.length > 0) {
    core.setFailed(`Failed to sync all SSM params:\n${syncErrors.join("\n")}`);
    return;
} else {
    console.log(`Secrets sychronized: ${successfulSyncs.join(', ')}`);
}