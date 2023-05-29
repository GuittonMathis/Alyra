// SPDX-License-Identifier: MIT
// version
pragma solidity >=0.8.2 <0.9.0;
//  importe le contrat "Ownable" de la bibliothèque OpenZeppelin
import "@openzeppelin/contracts/access/Ownable.sol";

contract Voting is
    Ownable // On déclare le contrat "Voting" qui hérite du contrat "Ownable".
{
    struct Voter {
        // une structure "Voter" qui stocke les informations sur un électeur
        bool isRegistered; // s'il est enregistré
        bool hasVoted; // s'il a voté
        uint256 votedProposalId; // et l'ID de son vote.
    }

    struct Proposal {
        //  une structure "Proposal" qui stocke les informations sur une proposition
        string description; // sa description
        uint256 voteCount; // le nombre de votes qu'elle a reçus
    }

    enum WorkflowStatus {
        //  une énumération "WorkflowStatus" qui gère les différents états du processus de vote
        RegisteringVoters, // l'enregistrement des électeurs
        ProposalsRegistrationStarted, //le début des propositions
        ProposalsRegistrationEnded, // la fin dess proposition
        VotingSessionStarted, //  le début des séssion de votes
        VotingSessionEnded, // la fin des session de votes
        VotesTallied // le dépouillement des votes / décompte des voix
    }

    WorkflowStatus public currentStatus; // déclare les variables publiques
    mapping(address => Voter) public voters; //  les informations des électeurs
    Proposal[] public proposals; // les propositions soumises par les électeurs
    uint256 public winningProposalId; //  l'ID de la proposition gagnante.

    event VoterRegistered(address voterAddress); // l'évenement de l'enregistrement d'un électeur
    event WorkflowStatusChange(
        WorkflowStatus previousStatus,
        WorkflowStatus newStatus
    );
    event ProposalRegistered(uint256 proposalId); // définit l'enregistrement d'une proposition
    event Voted(address voter, uint256 proposalId); // définit  le vote d'un électeur.

    constructor() {
        //  initialise l'état actuel du processus de vote à "RegisteringVoters"
        currentStatus = WorkflowStatus.RegisteringVoters;
    }

    modifier justRegisteredVoters() {
        // "justRegisteredVoters" est utilisé pour restreindre l'accès à certaines fonctions aux électeurs enregistrés
        require(
            voters[msg.sender].isRegistered,
            "Only registered voters are allowed."
        ); //  le require vérifie si l'adresse Ethereum de l'appelant (msg.sender) est enregistrée dans la liste des électeurs.
        _;
    }

    modifier justDuringStatus(WorkflowStatus expectedStatus) {
        require(currentStatus == expectedStatus, "Invalid workflow status."); // le require vérifie si la variable currentStatus est égale à la valeur attendue expectedStatus
        _;
    }

    function registerVoter(address _voterAddress)
        public
        onlyOwner
        justDuringStatus(WorkflowStatus.RegisteringVoters)
    {
        // la fonction "registerVoter" est utilisée par l'administrateur du vote pour enregistrer un électeur

        require(
            !voters[_voterAddress].isRegistered,
            "Voter is already registered."
        ); // en spécifiant son adresse _voterAddress
        voters[_voterAddress].isRegistered = true; //  le statut isRegistered du votant est mis à true
        emit VoterRegistered(_voterAddress); //  et un événement VoterRegistered est émis pour signaler cette action.
    }

    function startProposalsRegistration()
        public
        onlyOwner
        justDuringStatus(WorkflowStatus.RegisteringVoters)
    {
        // début du processus d'enregistrement des propositions
        currentStatus = WorkflowStatus.ProposalsRegistrationStarted; // mettant a jour l'état du workflow définissant currentStatus sur "ProposalsRegistrationStarted"
        emit WorkflowStatusChange(
            WorkflowStatus.RegisteringVoters,
            currentStatus
        ); // l'état précédent (RegisteringVoters) et le nouvel état (ProposalsRegistrationStarted).
    }

    function endProposalsRegistration()
        public
        onlyOwner
        justDuringStatus(WorkflowStatus.ProposalsRegistrationStarted)
    {
        // fin du processus d'enregistrement des propositions.
        currentStatus = WorkflowStatus.ProposalsRegistrationEnded; // mettant a jour l'état du workflow en définissant currentStatus sur "ProposalsRegistrationEnded"
        emit WorkflowStatusChange(
            WorkflowStatus.ProposalsRegistrationStarted,
            currentStatus
        ); // l'état précédent (ProposalsRegistrationStarted) et le nouvel état (ProposalsRegistrationEnded).
    }

    function startVotingSession()
        public
        onlyOwner
        justDuringStatus(WorkflowStatus.ProposalsRegistrationEnded)
    {
        // démarrer la session de vote
        currentStatus = WorkflowStatus.VotingSessionStarted; // A jour Wkf ...  en définissant currentStatus sur "VotingSessionStarted"
        emit WorkflowStatusChange(
            WorkflowStatus.ProposalsRegistrationEnded,
            currentStatus
        ); // // l'état précédent (ProposalsRegistrationEnded) et le nouvel état (VotingSessionStarted)
    }

    function endVotingSession()
        public
        onlyOwner
        justDuringStatus(WorkflowStatus.VotingSessionStarted)
    {
        // mes fin à la session de vote
        currentStatus = WorkflowStatus.VotingSessionEnded; // A jour Wkf ...  en définissant currentStatus sur "VotingSessionEnded"
        emit WorkflowStatusChange(
            WorkflowStatus.VotingSessionStarted,
            currentStatus
        ); //  l'état précédent (VotingSessionStarted) et le nouvel état (VotingSessionEnded)
    }

    function countVotes()
        public
        onlyOwner
        justDuringStatus(WorkflowStatus.VotingSessionEnded)
    {
        // décompte des votes terminé.
        currentStatus = WorkflowStatus.VotesTallied; // A jour Wkf ...  en définissant currentStatus sur "VotesTallied"
        emit WorkflowStatusChange(
            WorkflowStatus.VotingSessionEnded,
            currentStatus
        ); //  l'état précédent (VotingSessionEnded) et le nouvel état (VotesTallied)
        uint256 maxVoteCount = 0; // Variable utilisée pour suivre le nombre maximal de votes pour déterminer la proposition gagnante.
        for (uint256 i = 0; i < proposals.length; i++) {
            //  boucle for qui parcourt toutes les propositions du tableau proposals. L'index = i
            if (proposals[i].voteCount > maxVoteCount) {
                // Cette condition vérifie si le nombre de votes de proposals[i].voteCount et sup a maxVoteCount
                maxVoteCount = proposals[i].voteCount; // si conditions verifier alors maxVoteCount et =  avec le nombre de votes de la proposition actuelle
                winningProposalId = i;
            }
        }
    }

    //  fonctions permettant aux électeurs d'enregistrer leurs propositions et de voter
    function registerProposal(string memory _description)
        public
        justRegisteredVoters
        justDuringStatus(WorkflowStatus.ProposalsRegistrationStarted)
    {
        require(!voters[msg.sender].hasVoted, "Voter has already voted.");
        uint256 proposalId = proposals.length; // nouvelle variable proposalId,  attribue la longueur actuelle du tableau proposals comme valeur
        proposals.push(Proposal(_description, 0));
        emit ProposalRegistered(proposalId); // la proposition avec l'ID proposalId a été enregistrée avec succès".
    }

    //  fonction de vote
    function vote(uint256 _proposalId)
        public
        justRegisteredVoters
        justDuringStatus(WorkflowStatus.VotingSessionStarted)
    {
        require(!voters[msg.sender].hasVoted, "Voter has already voted."); // si l'électeur représenté par msg.sender a déjà voté la fonction est immédiatement arrêtée
        require(_proposalId < proposals.length, "Invalid proposal ID."); // vérifier que l'ID de la proposition pour lequel l'électeur veut voter est valide

        voters[msg.sender].hasVoted = true; // l'électeur qui appelle cette fonction a maintenant voté.
        voters[msg.sender].votedProposalId = _proposalId; //  enregistre l'ID de la proposition pour laquelle l'électeur a voté.
        proposals[_proposalId].voteCount++; //  augmente le compteur de votes de la proposition pour laquelle l'électeur a voté.

        emit Voted(msg.sender, _proposalId); //  émet un événement que le vote a eu lieu.
    }

    function getWinner() public view returns (string memory) {
        require(
            currentStatus == WorkflowStatus.VotesTallied,
            "Votes have not been tallied yet."
        ); // On s'assurer que l'état actuel du workflow  est VotesTallied.
        return proposals[winningProposalId].description; // renvoie la description de la proposition gagnante.
    }
}
