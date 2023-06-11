const { expect } = require("chai");
const { expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const Voting = artifacts.require("Voting");

contract("Voting", ([owner, voter1, voter2, nonVoter]) => {
    let voting;

    beforeEach(async () => {
        voting = await Voting.new({from: owner});
    });

    describe("Voter Registration", () => {
        it("should register a voter", async () => {
            const { receipt } = await voting.addVoter(voter1, {from: owner});
            expectEvent(receipt, 'VoterRegistered', { voterAddress: voter1 });
            
            const voter = await voting.getVoter(voter1, {from: voter1});
            expect(voter.isRegistered).to.equal(true);
        });

        it("should not allow to register a voter twice", async () => {
            await voting.addVoter(voter1, {from: owner});
            
            await expectRevert(
                voting.addVoter(voter1, {from: owner}),
                'Already registered'
            );
        });
        
        it("should revert when trying to register a voter while not in registration phase", async () => {
            await voting.startProposalsRegistering({ from: owner });
            await voting.endProposalsRegistering({ from: owner });

            await expectRevert(
                voting.addVoter(voter2, { from: owner }),
                'Voters registration is not open yet'
            );
        });

        it("should revert when trying to register a voter as a non-owner", async () => {
            await expectRevert(
              voting.addVoter(voter1, { from: nonVoter }),
              'Ownable: caller is not the owner'
            );
          });
    });

    describe("Proposal Registration", () => {
        it("should start proposal registration", async () => {
            const { receipt } = await voting.startProposalsRegistering({from: owner});
            expectEvent(receipt, 'WorkflowStatusChange', { newStatus: '1' });

            const status = await voting.workflowStatus();
            expect(status.toString()).to.equal('1');
        });

        it("should allow a registered voter to add a proposal", async () => {
            await voting.addVoter(voter1, {from: owner});
            await voting.startProposalsRegistering({from: owner});

            const { receipt } = await voting.addProposal("Proposal 1", {from: voter1});
            expectEvent(receipt, 'ProposalRegistered', { proposalId: '1' });

            const proposal = await voting.getOneProposal(1, {from: voter1});
            expect(proposal.description).to.equal("Proposal 1");
        });

        it("should revert when trying to add a proposal as a non-registered voter", async () => {
            await voting.startProposalsRegistering({ from: owner });
          
            await expectRevert(
              voting.addProposal("Proposal 1", { from: nonVoter }),
              "You're not a voter"
            );
          });
          
          it("should revert when trying to add an empty proposal", async () => {
            await voting.addVoter(voter1, { from: owner });
            await voting.startProposalsRegistering({ from: owner });
          
            await expectRevert(
              voting.addProposal("", { from: voter1 }),
              "Vous ne pouvez pas ne rien proposer"
            );
          });

    });

    describe("Voting Session", () => {
        it("should start voting session", async () => {
            await voting.startProposalsRegistering({from: owner});
            await voting.endProposalsRegistering({from: owner});

            const { receipt } = await voting.startVotingSession({from: owner});
            expectEvent(receipt, 'WorkflowStatusChange', { newStatus: '3' });

            const status = await voting.workflowStatus();
            expect(status.toString()).to.equal('3');
        });

        it("should allow a registered voter to vote", async () => {
            await voting.addVoter(voter1, {from: owner});
            await voting.startProposalsRegistering({from: owner});
            await voting.addProposal("Proposal 1", {from: voter1});
            await voting.endProposalsRegistering({from: owner});
            await voting.startVotingSession({from: owner});

            const { receipt } = await voting.setVote(1, {from: voter1});
            expectEvent(receipt, 'Voted', { voter: voter1, proposalId: '1' });

            const voter = await voting.getVoter(voter1, {from: voter1});
            expect(voter.hasVoted).to.equal(true);
        });

        it("should end voting session", async () => {
            await voting.startProposalsRegistering({from: owner});
            await voting.endProposalsRegistering({from: owner});
            await voting.startVotingSession({from: owner});

            const { receipt } = await voting.endVotingSession({from: owner});
            expectEvent(receipt, 'WorkflowStatusChange', { newStatus: '4' });

            const status = await voting.workflowStatus();
            expect(status.toString()).to.equal('4');
        });

        it("should revert when trying to vote before the voting session starts", async () => {
            await voting.addVoter(voter1, { from: owner });
            await voting.startProposalsRegistering({ from: owner });
            await voting.addProposal("Proposal 1", { from: voter1 });
            await voting.endProposalsRegistering({ from: owner });
          
            await expectRevert(
              voting.setVote(0, { from: voter1 }),
              "Voting session havent started yet"
            );
          });
          
          it("should revert when trying to vote for a non-existing proposal", async () => {
            await voting.addVoter(voter1, { from: owner });
            await voting.startProposalsRegistering({ from: owner });
            await voting.endProposalsRegistering({ from: owner });
            await voting.startVotingSession({ from: owner });
          
            await expectRevert(
              voting.setVote(1, { from: voter1 }),
              "Proposal not found"
            );
          });

    });

    describe("Vote Tally", () => {
        it("should tally votes", async () => {
            await voting.addVoter(voter1, {from: owner});
            await voting.addVoter(voter2, {from: owner});
            await voting.startProposalsRegistering({from: owner});
            await voting.addProposal("Proposal 1", {from: voter1});
            await voting.addProposal("Proposal 2", {from: voter2});
            await voting.endProposalsRegistering({from: owner});
            await voting.startVotingSession({from: owner});
            await voting.setVote(1, {from: voter1});
            await voting.setVote(2, {from: voter2});
            await voting.endVotingSession({from: owner});
            await voting.tallyVotes({from: owner});

            const winningProposalID = await voting.winningProposalID();
            expect(winningProposalID.toString()).to.equal('1');
        });

        it("should not allow to register a voter twice", async () => {
            await voting.addVoter(voter1, {from: owner});

            await expectRevert(
                voting.addVoter(voter1, {from: owner}),
                'Already registered'
            );
        });

        it("should revert when trying to tally votes before the voting session ends", async () => {
            await voting.addVoter(voter1, { from: owner });
            await voting.startProposalsRegistering({ from: owner });
            await voting.addProposal("Proposal 1", { from: voter1 });
            await voting.endProposalsRegistering({ from: owner });
            await voting.startVotingSession({ from: owner });
          
            await expectRevert(
              voting.tallyVotes({ from: owner }),
              "Current status is not voting session ended"
            );
          });

    });

    it("should not allow a registered voter to vote after voting session ended", async () => {
        await voting.addVoter(voter1, { from: owner });
        await voting.startProposalsRegistering({ from: owner });
        await voting.endProposalsRegistering({ from: owner });
        await voting.startVotingSession({ from: owner });
        await voting.endVotingSession({ from: owner });

        await expectRevert(
            voting.setVote(1, { from: voter1 }),
            "Voting session havent started yet"
        );
    });
    
    it("should not allow a registered voter to vote multiple times", async () => {
        await voting.addVoter(voter1, { from: owner });
        await voting.startProposalsRegistering({ from: owner });
        await voting.addProposal("Proposal 1", { from: voter1 });
        await voting.endProposalsRegistering({ from: owner });
        await voting.startVotingSession({ from: owner });
        await voting.setVote(1, { from: voter1 });

        await expectRevert(
            voting.setVote(1, { from: voter1 }),
            "You have already voted"
        );
    });

    it("should not allow a registered voter to modify a proposal after the end of proposal registration period", async () => {
        await voting.addVoter(voter1, { from: owner });
        await voting.startProposalsRegistering({ from: owner });
        await voting.addProposal("Proposal 1", { from: voter1 });
        await voting.endProposalsRegistering({ from: owner });

        await expectRevert(
            voting.addProposal("Modified Proposal 1", { from: voter1 }),
            "Proposals are not allowed yet"
        );
    });
});