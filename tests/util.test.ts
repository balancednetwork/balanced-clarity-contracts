import { describe, expect, it } from "vitest";
import { Cl } from "@stacks/transactions";
import { c32decode } from "c32check";

const UTIL_CONTRACT_NAME = "util";
const accounts = simnet.getAccounts();
const address1 = accounts.get("wallet_1")!;
const deployer = accounts.get("deployer");

const util = Cl.contractPrincipal(deployer!, UTIL_CONTRACT_NAME);

describe("address-string-to-principal", () => {
  it("should decode a valid c32check-encoded address", () => {
    const c32Address = "SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7";
    const expectedVersion = 0x00;
    const expectedData = c32decode(c32Address);

    const { result } = simnet.callReadOnlyFn(
      util.contractName.content,
      "decode-c32",
      [Cl.stringAscii(c32Address)],
      deployer!
    );

    console.log(c32decode(c32Address));
    console.log(Cl.prettyPrint(result));
  });
});

describe("address-string-to-principal", () => {
  it("should convert a standard principal string to principal", () => {
    const address = "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM";
    const { result } = simnet.callReadOnlyFn(
      util.contractName.content,
      "address-string-to-principal",
      [Cl.stringAscii(address)],
      deployer!
    );
    console.log(Cl.prettyPrint(result));
    expect(result).equal(Cl.principal(address));
  });
  // it("should convert a contract principal string to principal", () => {
  //   const address = "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc";
  //   const { result } = simnet.callReadOnlyFn(
  //     util.contractName.content,
  //     "address-string-to-principal",
  //     [Cl.stringAscii(address)],
  //     deployer!
  //   );
  //   expect(result).equal(Cl.principal(address));
  // });
  // it("should convert a contract principal string with a long contract name", () => {
  //   const address = "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.very-long-contract-name";
  //   const { result } = simnet.callReadOnlyFn(
  //     util.contractName.content,
  //     "address-string-to-principal",
  //     [Cl.stringAscii(address)],
  //     deployer!
  //   );
  //   expect(result).equal(Cl.principal(address));
  // });
  // it("should return an error for an invalid contract principal (missing period)", () => {
  //   const address = "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGMsbtc";
  //   const { result } = simnet.callReadOnlyFn(
  //     util.contractName.content,
  //     "address-string-to-principal",
  //     [Cl.stringAscii(address)],
  //     deployer!
  //   );
  //   // expect(result).toBeErr();
  // });
  // it("should return an error for an invalid address string (invalid characters)", () => {
  //   const address = "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM!";
  //   const { result } = simnet.callReadOnlyFn(
  //     util.contractName.content,
  //     "address-string-to-principal",
  //     [Cl.stringAscii(address)],
  //     deployer!
  //   );
  //   // expect(result).toBeErr();
  // });
  // it("should return an error for an empty address string", () => {
  //   const address = "";
  //   const { result } = simnet.callReadOnlyFn(
  //     util.contractName.content,
  //     "address-string-to-principal",
  //     [Cl.stringAscii(address)],
  //     deployer!
  //   );
  //   // expect(result).toBeErr();
  // });
  // it("should convert a standard principal with a period at the end", () => {
  //   const address = "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.";
  //   const { result } = simnet.callReadOnlyFn(
  //     util.contractName.content,
  //     "address-string-to-principal",
  //     [Cl.stringAscii(address)],
  //     deployer!
  //   );
  //   expect(result).equal(Cl.principal("ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM"));
  // });
  // it("should convert a contract principal with multiple periods", () => {
  //   const address = "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.contract.name";
  //   const { result } = simnet.callReadOnlyFn(
  //     util.contractName.content,
  //     "address-string-to-principal",
  //     [Cl.stringAscii(address)],
  //     deployer!
  //   );
  //   expect(result).equal(Cl.principal(address));
  // });
});
