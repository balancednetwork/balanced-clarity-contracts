import { describe, expect, it } from "vitest";
import { Cl } from "@stacks/transactions";
import { encode } from "rlp";

const ASSET_MANAGER_MESSAGES_CONTRACT_NAME = "asset-manager-messages";

describe("asset-manager-messages", () => {
  const accounts = simnet.getAccounts();
  const deployer = accounts.get("deployer");
  const assetManagerMessages = Cl.contractPrincipal(
    deployer!,
    ASSET_MANAGER_MESSAGES_CONTRACT_NAME
  );

  it("should encode Deposit message correctly", () => {
    const message = [
      "Deposit",
      "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc",
      "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM",
      "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.asset-manager",
      1000,
      "test message",
    ];

    const { result } = simnet.callPublicFn(
      assetManagerMessages.contractName.content,
      "encode-deposit",
      [
        Cl.tuple({
          tokenAddress: Cl.stringAscii(message[1] as string),
          from: Cl.stringAscii(message[2] as string),
          to: Cl.stringAscii(message[3] as string),
          amount: Cl.uint(parseInt(message[4] as string)),
          data: Cl.bufferFromAscii(message[5] as string),
        }),
      ],
      deployer!
    );

    const expectedEncodedData = Uint8Array.from(encode(message));
    // @ts-ignore: Property 'value' does not exist on type 'ClarityValue'. Property 'value' does not exist on type 'ContractPrincipalCV'.
    expect(result.value.buffer).toEqual(expectedEncodedData);
  });

  it("should encode DepositRevert message correctly", () => {
    const message = [
      "DepositRevert",
      "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc",
      1000,
      "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM",
    ];

    const { result } = simnet.callPublicFn(
      assetManagerMessages.contractName.content,
      "encode-deposit-revert",
      [
        Cl.tuple({
          tokenAddress: Cl.stringAscii(message[1] as string),
          amount: Cl.uint(parseInt(message[2] as string)),
          to: Cl.stringAscii(message[3] as string),
        }),
      ],
      deployer!
    );

    const expectedEncodedData = Uint8Array.from(encode(message));
    // @ts-ignore: Property 'value' does not exist on type 'ClarityValue'. Property 'value' does not exist on type 'ContractPrincipalCV'.
    expect(result.value.buffer).toEqual(expectedEncodedData);
  });

  it("should encode WithdrawTo message correctly", () => {
    const message = [
      "WithdrawTo",
      "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc",
      "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM",
      1000,
    ];

    const { result } = simnet.callPublicFn(
      assetManagerMessages.contractName.content,
      "encode-withdraw-to",
      [
        Cl.tuple({
          tokenAddress: Cl.stringAscii(message[1] as string),
          to: Cl.stringAscii(message[2] as string),
          amount: Cl.uint(parseInt(message[3] as string)),
        }),
      ],
      deployer!
    );

    const expectedEncodedData = Uint8Array.from(encode(message));
    // @ts-ignore: Property 'value' does not exist on type 'ClarityValue'. Property 'value' does not exist on type 'ContractPrincipalCV'.
    expect(result.value.buffer).toEqual(expectedEncodedData);
  });

  it("should encode WithdrawNativeTo message correctly", () => {
    const message = [
      "WithdrawNativeTo",
      "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc",
      "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM",
      1000,
    ];

    const { result } = simnet.callPublicFn(
      assetManagerMessages.contractName.content,
      "encode-withdraw-native-to",
      [
        Cl.tuple({
          tokenAddress: Cl.stringAscii(message[1] as string),
          to: Cl.stringAscii(message[2] as string),
          amount: Cl.uint(parseInt(message[3] as string)),
        }),
      ],
      deployer!
    );

    const expectedEncodedData = Uint8Array.from(encode(message));
    // @ts-ignore: Property 'value' does not exist on type 'ClarityValue'. Property 'value' does not exist on type 'ContractPrincipalCV'.
    expect(result.value.buffer).toEqual(expectedEncodedData);
  });

  it("should decode WithdrawTo message correctly", () => {
    const message = [
      "WithdrawTo",
      "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc",
      "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM",
      1000,
    ];

    const encodedData = Uint8Array.from(encode(message));

    const { result } = simnet.callReadOnlyFn(
      assetManagerMessages.contractName.content,
      "decode-withdraw-to",
      [Cl.buffer(encodedData)],
      deployer!
    );

    // @ts-ignore: Property 'value' does not exist on type 'ClarityValue'. Property 'value' does not exist on type 'ContractPrincipalCV'.
    expect(result.value).toEqual(
      Cl.tuple({
        "token-address": Cl.stringAscii(message[1] as string),
        to: Cl.stringAscii(message[2] as string),
        amount: Cl.uint(message[3]),
      })
    );
  });

  it("should decode DepositRevert message correctly", () => {
    const message = [
      "DepositRevert",
      "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc",
      1000,
      "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM",
    ];

    const encodedData = Uint8Array.from(encode(message));

    const { result } = simnet.callReadOnlyFn(
      assetManagerMessages.contractName.content,
      "decode-deposit-revert",
      [Cl.buffer(encodedData)],
      deployer!
    );

    // @ts-ignore: Property 'value' does not exist on type 'ClarityValue'. Property 'value' does not exist on type 'ContractPrincipalCV'.
    expect(result.value).toEqual(
      Cl.tuple({
        "token-address": Cl.stringAscii(message[1] as string),
        amount: Cl.uint(message[2]),
        to: Cl.stringAscii(message[3] as string),
      })
    );
  });

  it("should return the correct method for Deposit", () => {
    const message = [
      'Deposit',
      'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc',
      'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM',
      'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.asset-manager',
      1000,
      '1234',
    ];

    const encodedData = Uint8Array.from(encode(message));

    const { result } = simnet.callReadOnlyFn(
      assetManagerMessages.contractName.content,
      'get-method',
      [Cl.buffer(encodedData)],
      deployer!
    );

    expect(result).toBeOk(Cl.stringAscii('Deposit'));
  });

  it("should return the correct method for DepositRevert", () => {
    const message = [
      'DepositRevert',
      'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc',
      1000,
      'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM',
    ];

    const encodedData = Uint8Array.from(encode(message));

    const { result } = simnet.callReadOnlyFn(
      assetManagerMessages.contractName.content,
      'get-method',
      [Cl.buffer(encodedData)],
      deployer!
    );

    expect(result).toBeOk(Cl.stringAscii('DepositRevert'));
  });

  it("should return the correct method for WithdrawTo", () => {
    const message = [
      'WithdrawTo',
      'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc',
      'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM',
      1000,
    ];

    const encodedData = Uint8Array.from(encode(message));

    const { result } = simnet.callReadOnlyFn(
      assetManagerMessages.contractName.content,
      'get-method',
      [Cl.buffer(encodedData)],
      deployer!
    );

    expect(result).toBeOk(Cl.stringAscii('WithdrawTo'));
  });

  it("should return the correct method for WithdrawNativeTo", () => {
    const message = [
      'WithdrawNativeTo',
      'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc',
      'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM',
      1000,
    ];

    const encodedData = Uint8Array.from(encode(message));

    const { result } = simnet.callReadOnlyFn(
      assetManagerMessages.contractName.content,
      'get-method',
      [Cl.buffer(encodedData)],
      deployer!
    );

    expect(result).toBeOk(Cl.stringAscii('WithdrawNativeTo'));
  });

  it("should return ERR_INVALID_METHOD for an unknown method", () => {
    const message = [
      'UnknownMethod',
      'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc',
      'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM',
      1000,
    ];

    const encodedData = Uint8Array.from(encode(message));

    const { result } = simnet.callReadOnlyFn(
      assetManagerMessages.contractName.content,
      'get-method',
      [Cl.buffer(encodedData)],
      deployer!
    );

    expect(result).toBeErr(Cl.uint(100)); // ERR_INVALID_METHOD is defined as (err u100)
  });
});
