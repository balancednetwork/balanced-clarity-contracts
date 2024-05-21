import { describe, expect, it } from "vitest";
import { Cl } from "@stacks/transactions";
import { c32decode } from "c32check";

const UTIL_CONTRACT_NAME = "util";
const accounts = simnet.getAccounts();
const address1 = accounts.get("wallet_1")!;
const deployer = accounts.get("deployer");

const util = Cl.contractPrincipal(deployer!, UTIL_CONTRACT_NAME);

describe("address-string-to-principal", () => {
  it("should convert a standard principal string to principal", () => {
    const address = "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM";
    const { result } = simnet.callPublicFn(
      util.contractName.content,
      "address-string-to-principal",
      [Cl.stringAscii(address)],
      deployer!
    );

    expect(result).toBeOk(Cl.principal(address));
  });

  it("should convert a contract principal string to principal", () => {
    const address = "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc";
    const { result } = simnet.callPublicFn(
      util.contractName.content,
      "address-string-to-principal",
      [Cl.stringAscii(address)],
      deployer!
    );
    expect(result).toBeOk(Cl.principal(address));
  });

  it("should convert a contract principal string with a long contract name", () => {
    const address = "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.very-long-contract-name";
    const { result } = simnet.callPublicFn(
      util.contractName.content,
      "address-string-to-principal",
      [Cl.stringAscii(address)],
      deployer!
    );
    expect(result).toBeOk(Cl.principal(address));
  });

  it("should return an error for an invalid contract principal (missing period)", () => {
    const address = "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGMsbtc";
    const { result } = simnet.callPublicFn(
      util.contractName.content,
      "address-string-to-principal",
      [Cl.stringAscii(address)],
      deployer!
    );

    expect(result).toBeErr(Cl.uint(1000));
  });

  it("should return an error for an invalid address string (invalid characters)", () => {
    const address = "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGU";
    const { result } = simnet.callPublicFn(
      util.contractName.content,
      "address-string-to-principal",
      [Cl.stringAscii(address)],
      deployer!
    );

    expect(result).toBeErr(Cl.uint(1000));
  });

  it("should return an error for an empty address string", () => {
    const address = "";
    const { result } = simnet.callReadOnlyFn(
      util.contractName.content,
      "address-string-to-principal",
      [Cl.stringAscii(address)],
      deployer!
    );
    expect(result).toBeErr(Cl.uint(1000));
  });
});
