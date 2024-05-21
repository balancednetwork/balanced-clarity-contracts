import { describe, expect, it } from "vitest";
import { Cl } from "@stacks/transactions";
import { encode } from "rlp";

const ASSET_MANAGER_CONTRACT_NAME = "asset-manager";
const ICON_ASSET_MANAGER = "0x1.icon/cxabea09a8c5f3efa54d0a0370b14715e6f2270591";
const X_CALL_NETWORK_ADDRESS = "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.x-call";

describe("asset-manager", () => {
  const accounts = simnet.getAccounts();
  const deployer = accounts.get("deployer");
  const user = accounts.get("wallet_1")!;
  const assetManager = Cl.contractPrincipal(
    deployer!,
    ASSET_MANAGER_CONTRACT_NAME
  );

  it("allows members to deposit native tokens", () => {
    const amount = 1000;
  
    const { result } = simnet.callPublicFn(
      assetManager.contractName.content,
      "deposit-native",
      [Cl.uint(amount)],
      user
    );
  
    expect(result).toBeOk(Cl.bool(true));
  });

  it("allows members to deposit tokens", () => {
    const token = Cl.contractPrincipal(deployer!, "sbtc");
    const amount = 1000;

    simnet.callPublicFn(
      token.contractName.content,
      "mint",
      [Cl.uint(amount), Cl.address(user)],
      deployer!
    );

    const { result } = simnet.callPublicFn(
      assetManager.contractName.content,
      "deposit",
      [token, Cl.uint(amount)],
      user
    );

    expect(result).toBeOk(Cl.bool(true));
  });

  it("allows the contract owner to configure rate limit", () => {
    const token = Cl.contractPrincipal(deployer!, "sbtc");
    const amount = 1000;
    const newPeriod = 10000;
    const newPercentage = 9000;

    simnet.callPublicFn(
      token.contractName.content,
      "mint",
      [Cl.uint(amount), Cl.address(user)],
      deployer!
    );
    simnet.callPublicFn(
      assetManager.contractName.content,
      "deposit",
      [token, Cl.uint(amount)],
      user
    );

    const { result } = simnet.callPublicFn(
      assetManager.contractName.content,
      "configure-rate-limit",
      [token, Cl.uint(newPeriod), Cl.uint(newPercentage)],
      deployer!
    );

    expect(result).toBeOk(Cl.bool(true));

    const { result: periodResult } = simnet.callReadOnlyFn(
      assetManager.contractName.content,
      "get-period",
      [token],
      deployer!
    );
    expect(periodResult).toBeUint(newPeriod);

    const { result: percentageResult } = simnet.callReadOnlyFn(
      assetManager.contractName.content,
      "get-percentage",
      [token],
      deployer!
    );
    expect(percentageResult).toBeUint(newPercentage);

    const { result: limitResult } = simnet.callReadOnlyFn(
      assetManager.contractName.content,
      "get-current-limit",
      [token],
      deployer!
    );
    const expectedLimit = Math.floor((amount * newPercentage) / 10000);
    expect(limitResult).toBeUint(expectedLimit);
  });

  it("allows the contract owner to reset the withdrawal limit", () => {
    const token = Cl.contractPrincipal(deployer!, "sbtc");
    const initialAmount = 1000;
    const initialPercentage = 9000;

    simnet.callPublicFn(
      token.contractName.content,
      "mint",
      [Cl.uint(initialAmount), Cl.address(user)],
      deployer!
    );
    simnet.callPublicFn(
      assetManager.contractName.content,
      "deposit",
      [token, Cl.uint(initialAmount)],
      user
    );
    simnet.callPublicFn(
      assetManager.contractName.content,
      "configure-rate-limit",
      [token, Cl.uint(10000), Cl.uint(initialPercentage)],
      deployer!
    );
  
    const { result: resetResult } = simnet.callPublicFn(
      assetManager.contractName.content,
      "reset-limit",
      [token],
      deployer!
    );
    expect(resetResult).toBeOk(Cl.bool(true));
  
    const { result: limitResult } = simnet.callReadOnlyFn(
      assetManager.contractName.content,
      "get-current-limit",
      [token],
      deployer!
    );
    const expectedLimit = Math.floor((initialAmount * initialPercentage) / 10000);
    expect(limitResult).toBeUint(expectedLimit);
  });

  it("allows withdrawal when limit is not exceeded", () => {
    const token = Cl.contractPrincipal(deployer!, "sbtc");
    const amount = 1000;
    const withdrawalAmount = 899;
    const newPeriod = 10000;
    const newPercentage = 9000;
    const allowedWithdrawal = ((amount * newPercentage) / 10000) - 1;

    expect(withdrawalAmount).toBeLessThanOrEqual(allowedWithdrawal);

    simnet.callPublicFn(
      token.contractName.content,
      "mint",
      [Cl.uint(amount), Cl.address(user)],
      deployer!
    );

    simnet.callPublicFn(
      assetManager.contractName.content,
      "deposit",
      [token, Cl.uint(amount)],
      user
    );

    simnet.callPublicFn(
      assetManager.contractName.content,
      "configure-rate-limit",
      [token, Cl.uint(newPeriod), Cl.uint(newPercentage)],
      deployer!
    );

    simnet.mineBlock([]);

    const { result } = simnet.callPublicFn(
      assetManager.contractName.content,
      "withdraw",
      [token, Cl.uint(withdrawalAmount), Cl.address(user)],
      user
    );

    expect(result).toBeOk(Cl.bool(true));
  });

  it("does not allow withdrawal exceeding limit", () => {
    const token = Cl.contractPrincipal(deployer!, "sbtc");
    const amount = 1000;
    const withdrawalAmount = 900;
    const newPeriod = 10000;
    const newPercentage = 9000;

    const allowedWithdrawal = ((amount * newPercentage) / 10000) - 1;

    expect(withdrawalAmount).toBeGreaterThan(allowedWithdrawal);

    simnet.callPublicFn(
      token.contractName.content,
      "mint",
      [Cl.uint(amount), Cl.address(user)],
      deployer!
    );

    simnet.callPublicFn(
      assetManager.contractName.content,
      "deposit",
      [token, Cl.uint(amount)],
      user
    );
    simnet.callPublicFn(
      assetManager.contractName.content,
      "configure-rate-limit",
      [token, Cl.uint(newPeriod), Cl.uint(newPercentage)],
      deployer!
    );

    const { result } = simnet.callPublicFn(
      assetManager.contractName.content,
      "withdraw",
      [token, Cl.uint(withdrawalAmount), Cl.address(user)],
      user
    );

    expect(result).toBeErr(Cl.uint(102));
  });

  it("should handle WithdrawTo message correctly", () => {
    const message = [
      'WithdrawTo',
      'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc',
      'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM',
      1000,
    ];

    const encodedData = Uint8Array.from(encode(message));

    const { result } = simnet.callPublicFn(
      assetManager.contractName.content,
      'handle-call-message',
      [
        Cl.stringAscii(ICON_ASSET_MANAGER),
        Cl.buffer(encodedData),
        Cl.list([]),
      ],
      deployer!
    );

    console.log(Cl.prettyPrint(result));
  });

  it("should handle DepositRevert message correctly", () => {
    const message = [
      'DepositRevert',
      'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc',
      1000,
      'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM',
    ];

    const encodedData = Uint8Array.from(encode(message));

    const { result } = simnet.callPublicFn(
      assetManager.contractName.content,
      'handle-call-message',
      [
        Cl.stringAscii(X_CALL_NETWORK_ADDRESS),
        Cl.buffer(encodedData),
        Cl.list([]),
      ],
      deployer!
    );

    console.log(Cl.prettyPrint(result));
  });

  it("should fail to handle WithdrawTo message if the sender is not ICON_ASSET_MANAGER", () => {
    const message = [
      'WithdrawTo',
      'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc',
      'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM',
      1000,
    ];

    const encodedData = Uint8Array.from(encode(message));

    const { result } = simnet.callPublicFn(
      assetManager.contractName.content,
      'handle-call-message',
      [
        Cl.stringAscii('0x1.icon/cxabea09a8c5f3efa54d0a0370b14715e6f2270592'),
        Cl.buffer(encodedData),
        Cl.list([]),
      ],
      deployer!
    );

    expect(result).toBeErr(Cl.uint(100));
  });

  it("should fail to handle DepositRevert message if the sender is not X_CALL_NETWORK_ADDRESS", () => {
    const message = [
      'DepositRevert',
      'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc',
      1000,
      'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM',
    ];

    const encodedData = Uint8Array.from(encode(message));

    const { result } = simnet.callPublicFn(
      assetManager.contractName.content,
      'handle-call-message',
      [
        Cl.stringAscii('ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGX.x-call'),
        Cl.buffer(encodedData),
        Cl.list([]),
      ],
      deployer!
    );

    expect(result).toBeErr(Cl.uint(100));
  });

  it("should fail to handle WithdrawNativeTo message", () => {
    const message = [
      'WithdrawNativeTo',
      'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM',
      1000,
    ];
  
    const encodedData = Uint8Array.from(encode(message));
  
    const { result } = simnet.callPublicFn(
      assetManager.contractName.content,
      'handle-call-message',
      [
        Cl.stringAscii(ICON_ASSET_MANAGER),
        Cl.buffer(encodedData),
        Cl.list([]),
      ],
      deployer!
    );
  
    expect(result).toBeErr(Cl.uint(105));
  });

  it("should fail to handle unknown message types", () => {
    const message = [
      'UnknownMessage',
      'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc',
      'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM',
      1000,
    ];

    const encodedData = Uint8Array.from(encode(message));

    const { result } = simnet.callPublicFn(
      assetManager.contractName.content,
      'handle-call-message',
      [
        Cl.stringAscii(ICON_ASSET_MANAGER),
        Cl.buffer(encodedData),
        Cl.list([]),
      ],
      deployer!
    );

    expect(result).toBeErr(Cl.uint(104));
  });
});
