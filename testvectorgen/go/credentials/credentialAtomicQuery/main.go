package main

import (
	"context"
	"encoding/json"
	"fmt"
	core "github.com/iden3/go-iden3-core"
	"github.com/iden3/go-merkletree-sql"
	"github.com/iden3/go-merkletree-sql/db/memory"
	"math/big"
	"test/utils"
	"time"
)

func main() {

	// Generate inputs for attributeQuery.circom
	attributeQuery()
}

func attributeQuery() {
	fmt.Println("\n-------\ntest vectors for credentialAtomicQuery:")
	userPrivKHex := "28156abe7fe2fd433dc9df969286b96666489bac508612d0e16593e944c4f69f"
	issuerPrivKHex := "21a5e7321d0e2f3ca1cc6504396e6594a2211544b08c206847cdee96f832421a"
	challenge := new(big.Int).SetInt64(12345)

	ctx := context.Background()

	// User
	userIdentity, uClaimsTree, userInputs := utils.GenerateIdentity(ctx, userPrivKHex, challenge)

	fmt.Printf("\n signatures end -------- \n\n")

	// Issuer
	_, iClaimsTree, issuerInputs := utils.GenerateIdentity(ctx, issuerPrivKHex, challenge)

	fmt.Println(uClaimsTree)
	utils.PrintMap(userInputs)
	utils.PrintMap(issuerInputs)

	// issue claim for user
	dataSlotA, _ := core.NewDataSlotFromInt(big.NewInt(10))
	nonce := 1
	var schemaHash core.SchemaHash
	copy(schemaHash[:], "1")

	claim, err := core.NewClaim(
		schemaHash,
		core.WithIndexID(*userIdentity),
		core.WithIndexData(dataSlotA, core.DataSlot{}),
		core.WithExpirationDate(time.Unix(1669884010, 0)), //Thu Dec 01 2022 08:40:10 GMT+0000
		core.WithRevocationNonce(uint64(nonce)))
	utils.ExitOnError(err)

	// addClaimToIssuerTree
	proof, err := utils.AddClaimToTree(iClaimsTree, claim)
	utils.ExitOnError(err)

	// Calim proof
	proofSib, err := json.Marshal(proof.AllSiblings())
	utils.ExitOnError(err)

	fmt.Println("proofSib:", string(proofSib))

	cIn, err := utils.ClaimToString(claim)
	utils.ExitOnError(err)

	fmt.Println("cIn:", cIn)

	fmt.Println("issuer claim tree root:", iClaimsTree.Root().BigInt().String())
	fmt.Println("current issuer state:")
	utils.PrintCurrentState(iClaimsTree)

	issuerRevTreeStorage := memory.NewMemoryStorage()
	issuerRevTree, err := merkletree.NewMerkleTree(ctx, issuerRevTreeStorage, 4)
	utils.ExitOnError(err)

	generateProof, _, err := issuerRevTree.GenerateProof(context.TODO(), big.NewInt(int64(nonce)), issuerRevTree.Root())
	utils.ExitOnError(err)

	//Revocation proof inputs
	fmt.Println("Revocation 1 proofs")
	marshal, err := json.Marshal(generateProof.AllSiblings())
	utils.ExitOnError(err)

	fmt.Println("Marshaled all siblings", string(marshal))

	fmt.Println("existence:", generateProof.Existence)
	fmt.Println("NodeAux ", generateProof.NodeAux)
	//fmt.Println("NodeAux Key:",proof.NodeAux.Key.BigInt().String())
	//fmt.Println("NodeAux Value:",proof.NodeAux.Value.BigInt().String())

	fmt.Println("Rev tree state:", iClaimsTree.Root().BigInt().String())
	fmt.Println("Rev tree issuer state:")
	utils.PrintCurrentState(iClaimsTree)

}
