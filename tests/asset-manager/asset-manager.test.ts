import { describe, expect, it } from 'vitest';
import { Cl } from '@stacks/transactions';

const DEPLOYER_DEVNET_STX_ADDRESS = 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM'  // initialized in settings/devnet.toml
const ASSET_MANAGER_CONTRACT_NAME = 'asset-manager' // naming convention is contract filename without the file extension

describe('asset-manager', () => {
  const accounts = simnet.getAccounts();
  const deployer = accounts.get('deployer');
  const user = accounts.get('wallet_1')!;
  const owner = accounts.get('wallet_2')!;
  const assetManager = Cl.contractPrincipal(deployer || DEPLOYER_DEVNET_STX_ADDRESS, ASSET_MANAGER_CONTRACT_NAME);
  console.log(Cl.prettyPrint(assetManager));
  const xCall = Cl.contractPrincipal(deployer || DEPLOYER_DEVNET_STX_ADDRESS, 'xCall');
  const xCallManager = Cl.contractPrincipal(deployer || DEPLOYER_DEVNET_STX_ADDRESS, 'xCallManager');
  // const token = Cl.contractPrincipal(deployer || DEPLOYER_DEVNET_STX_ADDRESS, 'token');

  // it('allows the contract owner to initialize the vault', () => {
  //   const { result } = simnet.callPublicFn(assetManager, 'initialize', [
  //     xCall,
  //     Cl.stringAscii('icon-asset-manager'),
  //     xCallManager
  //   ], user);
    
  //   expect(result).toBeOk(Cl.bool(true));
  // });

  // it('does not allow anyone else to initialize the vault', () => {
  //   const address2 = simnet.getAccounts().get('wallet_2')!;
  //   const { result } = simnet.callPublicFn(assetManager, 'initialize', [
  //     xCall, 
  //     Cl.stringAscii('icon-asset-manager'),
  //     xCallManager
  //   ], address2);
    
  //   expect(result).toBeErr(Cl.uint(100));
  // });

  // it('allows members to deposit tokens', () => {
  //   simnet.callPublicFn(assetManager, 'initialize', [
  //     xCall, 
  //     Cl.stringAscii('icon-asset-manager'),
  //     xCallManager
  //   ], user);

  //   const amount = 1000;
  //   simnet.callPublicFn(token, 'transfer', [
  //     Cl.uint(amount),
  //     assetManager,
  //     user
  //   ], user);

  //   const { result } = simnet.callPublicFn(assetManager, 'deposit', [
  //     token,
  //     Cl.uint(amount)
  //   ], user);

  //   expect(result).toBeOk(Cl.bool(true));

  //   const balance = simnet.callReadOnlyFn(token, 'balanceOf', [user], user);
  //   expect(balance.result).toBeOk(Cl.uint(0));

  //   const assetManagerBalance = simnet.callReadOnlyFn(token, 'balanceOf', [assetManager], user);
  //   expect(assetManagerBalance.result).toBeOk(Cl.uint(amount));
  // });

  // it('allows anyone to send native tokens to the contract', () => {
  //   simnet.callPublicFn(assetManager, 'initialize', [
  //     xCall, 
  //     Cl.stringAscii('icon-asset-manager'),
  //     xCallManager
  //   ], user);

  //   const amount = 1000;
  //   simnet.transferSTX(amount, assetManager, user);

  //   const balance = simnet.callReadOnlyFn(assetManager, 'getBalance', [], user);
  //   expect(balance.result).toBeOk(Cl.uint(amount));
  // });

  // it('does not allow non-xCall to call handleCallMessage', () => {
  //   const protocol = [Cl.stringAscii('eth'), Cl.stringAscii('icon')];
  //   const { result } = simnet.callPublicFn(assetManager, 'handleCallMessage', [
  //     Cl.stringAscii('from-contract'),
  //     xCall,
  //     Cl.list(protocol)
  //   ], owner);

  //   expect(result).toBeErr(Cl.uint(100));
  // });

  // it('allows withdrawal when vote threshold is reached', () => {
  //   simnet.callPublicFn(assetManager, 'initialize', [
  //     xCall, 
  //     Cl.stringAscii('icon-asset-manager'),
  //     xCallManager
  //   ], user);

  //   const amount = 1000;
  //   simnet.callPublicFn(token, 'transfer', [
  //     Cl.uint(amount),
  //     assetManager,
  //     user
  //   ], user);

  //   simnet.callPublicFn(assetManager, 'deposit', [
  //     token,
  //     Cl.uint(amount)
  //   ], user);

  //   simnet.callPublicFn(assetManager, 'setVotesThreshold', [
  //     Cl.uint(1)
  //   ], user);

  //   simnet.callPublicFn(assetManager, 'voteWithdraw', [
  //     token,
  //     Cl.uint(amount),
  //     user
  //   ], user);

  //   const { result } = simnet.callPublicFn(assetManager, 'withdraw', [
  //     token,
  //     Cl.uint(amount)  
  //   ], user);

  //   expect(result).toBeOk(Cl.bool(true));

  //   const balance = simnet.callReadOnlyFn(token, 'balanceOf', [user], user);
  //   expect(balance.result).toBeOk(Cl.uint(amount));

  //   const assetManagerBalance = simnet.callReadOnlyFn(token, 'balanceOf', [assetManager], user);
  //   expect(assetManagerBalance.result).toBeOk(Cl.uint(0));
  // });
});