import { describe, expect, it } from 'vitest';
import { Cl } from '@stacks/transactions';

const ASSET_MANAGER_CONTRACT_NAME = 'asset-manager' // naming convention is contract filename without the file extension

describe('asset-manager', () => {
  const accounts = simnet.getAccounts();
  const deployer = accounts.get('deployer');
  const user = accounts.get('wallet_1')!;
  const assetManager = Cl.contractPrincipal(deployer!, ASSET_MANAGER_CONTRACT_NAME);

  it('allows the contract owner to configure rate limit', () => {
    const token = Cl.contractPrincipal(deployer!, 'token');
    const newPeriod = 10000; 
    const newPercentage = 9000;
    
    const { result } = simnet.callPublicFn(assetManager.contractName.content, 'configure-rate-limit', [
      token,
      Cl.uint(newPeriod), 
      Cl.uint(newPercentage)
    ], deployer!);
    
    expect(result).toBeOk(Cl.bool(true));
  });

  // it('allows members to deposit tokens', () => {
  //   const token = Cl.contractPrincipal(deployer || DEPLOYER_DEVNET_STX_ADDRESS, 'token');
  //   const amount = 1000;

  //   const { result } = simnet.callPublicFn(assetManager.contractName.content, 'deposit', [
  //     token,
  //     Cl.uint(amount)
  //   ], user);

  //   expect(result).toBeOk(Cl.bool(true));
  // });

  // it('allows withdrawal when limit is not exceeded', () => {
  //   const token = Cl.contractPrincipal(deployer || DEPLOYER_DEVNET_STX_ADDRESS, 'token');
  //   const amount = 1000;
  //   const withdrawalAmount = 900;

  //   simnet.callPublicFn(assetManager.contractName.content, 'deposit', [
  //     token,
  //     Cl.uint(amount)
  //   ], user);
  //   simnet.callPublicFn(assetManager.contractName.content, 'configure-rate-limit', [
  //     token, 
  //     Cl.uint(10000),
  //     Cl.uint(9000)
  //   ], deployer!);

  //   const { result } = simnet.callPublicFn(assetManager.contractName.content, 'withdraw', [
  //     token,
  //     Cl.uint(withdrawalAmount),
  //     Cl.address(user)
  //   ], user);

  //   expect(result).toBeOk(Cl.bool(true));
  // });

  // it('does not allow withdrawal exceeding limit', () => {
  //   const token = Cl.contractPrincipal(deployer || DEPLOYER_DEVNET_STX_ADDRESS, 'token');
  //   const amount = 1000;
  //   const withdrawalAmount = 901;

  //   simnet.callPublicFn(assetManager.contractName.content, 'deposit', [
  //     token,
  //     Cl.uint(amount)
  //   ], user);
  //   simnet.callPublicFn(assetManager.contractName.content, 'configure-rate-limit', [
  //     token, 
  //     Cl.uint(10000),
  //     Cl.uint(9000)
  //   ], deployer!);

  //   const { result } = simnet.callPublicFn(assetManager.contractName.content, 'withdraw', [
  //     token,
  //     Cl.uint(withdrawalAmount),
  //     Cl.address(user)
  //   ], user);

  //   expect(result).toBeErr(Cl.uint(102)); // ERR_EXCEED_WITHDRAW_LIMIT
  // });
});