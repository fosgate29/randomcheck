const { time, loadFixture } = require('@nomicfoundation/hardhat-network-helpers');
const { anyValue } = require('@nomicfoundation/hardhat-chai-matchers/withArgs');
const { expect } = require('chai');

describe('RandomCheck', function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployRandomFixture() {
    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await ethers.getSigners();
    const uri = 'http://sth';

    const RandomCheck = await ethers.getContractFactory('RandomCheck');
    const randomCheck = await RandomCheck.deploy(uri);

    return { randomCheck, owner, otherAccount, uri };
  }

  describe('Deployment', function () {
    it('Should mint 10 tokens of id 1', async function () {
      const { randomCheck, owner } = await loadFixture(deployRandomFixture);

      await randomCheck.mint();
      expect(await randomCheck.balanceOf(owner.address, 1)).to.equal(10);
    });

    it('Should random mint', async function () {
      const { randomCheck } = await loadFixture(deployRandomFixture);

      await randomCheck.randomMint();
    });
  });
});
