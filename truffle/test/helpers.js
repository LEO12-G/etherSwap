const EVM_REVERT = "VM Exception while processing transcation: revert"

const tokens = (n) =>{
    return new web3.utils.BN(
        web3.utils.toWei(n.toString(),'ether')
    )
}