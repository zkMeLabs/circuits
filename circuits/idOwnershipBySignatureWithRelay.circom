/*
Circuit to check that the prover is the owner of the identity
- prover is owner of the private key
- prover public key is in a ClaimKeyBBJJ that is inside its Identity State (in Claim tree)
- the Identity State, in turn, is inside Relay state as specific claim
*/

pragma circom 2.0.0;

include "verifyAuthClaimAndSignature.circom";
include "credential.circom";

template IdOwnershipBySignatureWithRelay(nLevelsUser, nLevelsRelay) {

    /*
    >>>>>>>>>>>>>>>>>>>>>>>>>>> Inputs <<<<<<<<<<<<<<<<<<<<<<<<<<<<
    */

	signal input claimsTreeRoot;
	signal input authClaimMtp[nLevelsUser];
	signal input authClaim[8];

	signal input revTreeRoot;
    signal input authClaimNonRevMtp[nLevelsUser];
    signal input authClaimNonRevMtpNoAux;
    signal input authClaimNonRevMtpAuxHi;
    signal input authClaimNonRevMtpAuxHv;

	signal input rootsTreeRoot;

	signal input challenge;
	signal input challengeSignatureR8x;
	signal input challengeSignatureR8y;
	signal input challengeSignatureS;

    signal input userID;

    signal input relayState;
    signal input userStateInRelayClaimMtp[nLevelsRelay];
    signal input userStateInRelayClaim[8];
	signal input relayProofValidClaimsTreeRoot;
	signal input relayProofValidRevTreeRoot;
	signal input relayProofValidRootsTreeRoot;

    /*
    >>>>>>>>>>>>>>>>>>>>>>>>>>> End Inputs <<<<<<<<<<<<<<<<<<<<<<<<<<<<
    */

    component verifyAuthClaim = VerifyAuthClaimAndSignature(nLevelsUser);
    for (var i=0; i<8; i++) { verifyAuthClaim.authClaim[i] <== authClaim[i]; }
	for (var i=0; i<nLevelsUser; i++) { verifyAuthClaim.authClaimMtp[i] <== authClaimMtp[i]; }
	verifyAuthClaim.claimsTreeRoot <== claimsTreeRoot;
	verifyAuthClaim.revTreeRoot <== revTreeRoot;
	for (var i=0; i<nLevelsUser; i++) { verifyAuthClaim.authClaimNonRevMtp[i] <== authClaimNonRevMtp[i]; }
	verifyAuthClaim.authClaimNonRevMtpNoAux <== authClaimNonRevMtpNoAux;
	verifyAuthClaim.authClaimNonRevMtpAuxHv <== authClaimNonRevMtpAuxHv;
	verifyAuthClaim.authClaimNonRevMtpAuxHi <== authClaimNonRevMtpAuxHi;

    verifyAuthClaim.challengeSignatureS <== challengeSignatureS;
    verifyAuthClaim.challengeSignatureR8x <== challengeSignatureR8x;
    verifyAuthClaim.challengeSignatureR8y <== challengeSignatureR8y;
    verifyAuthClaim.challenge <== challenge;

	// get claim for identity state and check that it is included into Relay's state

    component checkUserState = verifyIdenStateMatchesRoots();
    checkUserState.isProofValidClaimsTreeRoot <== claimsTreeRoot;
    checkUserState.isProofValidRevTreeRoot <== revTreeRoot;
    checkUserState.isProofValidRootsTreeRoot <== rootsTreeRoot;
    checkUserState.isIdenState <== userStateInRelayClaim[6];

    // verify relay claim schema
     var RELAY_SCHEMA_HASH  = 300643596977370539894307577071173136726; // hex e22dd9c0f7aef15788c130d4d86c7156
     component verifyRelaySchema  = verifyCredentialSchema();
     for (var i=0; i<8; i++) {
          verifyRelaySchema.claim[i] <== userStateInRelayClaim[i];
     }
     verifyRelaySchema.schema <== RELAY_SCHEMA_HASH;

	component header = getClaimHeader();
	for (var i=0; i<8; i++) { header.claim[i] <== userStateInRelayClaim[i]; }

	component subjectOtherIden = getClaimSubjectOtherIden(0);
	for (var i=0; i<8; i++) { subjectOtherIden.claim[i] <== userStateInRelayClaim[i]; }
	for (var i=0; i<32; i++) { subjectOtherIden.claimFlags[i] <== header.claimFlags[i]; }

    userID === subjectOtherIden.id;

    component checkUserStateInRelay = checkClaimExists(nLevelsRelay);
    for (var i=0; i<8; i++) { checkUserStateInRelay.claim[i] <== userStateInRelayClaim[i]; }
	for (var i=0; i<nLevelsRelay; i++) { checkUserStateInRelay.claimMTP[i] <== userStateInRelayClaimMtp[i]; }
    checkUserStateInRelay.treeRoot <== relayProofValidClaimsTreeRoot;

    component checkRelayState = verifyIdenStateMatchesRoots();
    checkRelayState.isProofValidClaimsTreeRoot <== relayProofValidClaimsTreeRoot;
    checkRelayState.isProofValidRevTreeRoot <== relayProofValidRevTreeRoot;
    checkRelayState.isProofValidRootsTreeRoot <== relayProofValidRootsTreeRoot;
    checkRelayState.isIdenState <== relayState;
}
