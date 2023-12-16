import Result "mo:base/Result";
import HashMap "mo:base/HashMap";
import TrieMap "mo:base/TrieMap";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Account "account";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";
import Blob "mo:base/Blob";
import Debug "mo:base/Debug";
import Http "http";
import Nat "mo:base/Nat";
import Hash "mo:base/Hash";
actor class DAO()  {

    // For the logic of this level we need to bring back all the previous levels

    ///////////////
    // LEVEL #1 //
    /////////////

    let name : Text = "Motoko Bootcamp DAO";
    var manifesto : Text = "Empower the next wave of builders to make the Web3 revolution a reality";

    let goals : Buffer.Buffer<Text> = Buffer.Buffer<Text>(0);

    public shared query func getName() : async Text {
        return name;
    };

    public shared query func getManifesto() : async Text {
        return manifesto;
    };

    public func setManifesto(newManifesto : Text) : async () {
        manifesto := newManifesto;
        return;
    };

    public func addGoal(newGoal : Text) : async () {
        goals.add(newGoal);
        return;
    };

    public shared query func getGoals() : async [Text] {
        return Buffer.toArray(goals);
    };

    ///////////////
    // LEVEL #2 //
    /////////////

    public type Member = {
        name : Text;
        age : Nat;
    };
    public type Result<A, B> = Result.Result<A, B>;
    public type HashMap<A, B> = HashMap.HashMap<A, B>;

    let dao : HashMap<Principal, Member> = HashMap.HashMap<Principal, Member>(0, Principal.equal, Principal.hash);

    public shared ({ caller }) func addMember(member : Member) : async Result<(), Text> {
        switch (dao.get(caller)) {
            case (?member) {
                return #err("Already a member");
            };
            case (null) {
                dao.put(caller, member);
                return #ok(());
            };
        };
    };

    public shared ({ caller }) func updateMember(member : Member) : async Result<(), Text> {
        switch (dao.get(caller)) {
            case (?member) {
                dao.put(caller, member);
                return #ok(());
            };
            case (null) {
                return #err("Not a member");
            };
        };
    };

    public shared ({ caller }) func removeMember() : async Result<(), Text> {
        switch (dao.get(caller)) {
            case (?member) {
                dao.delete(caller);
                return #ok(());
            };
            case (null) {
                return #err("Not a member");
            };
        };
    };

    public query func getMember(p : Principal) : async Result<Member, Text> {
        switch (dao.get(p)) {
            case (?member) {
                return #ok(member);
            };
            case (null) {
                return #err("Not a member");
            };
        };
    };

    public query func getAllMembers() : async [Member] {
        Iter.toArray(dao.vals());
    };

    public query func numberOfMembers() : async Nat {
        return dao.size();
    };

    ///////////////
    // LEVEL #3 //
    /////////////

    public type Subaccount = Blob;
    public type Account = {
        owner : Principal;
        subaccount : ?Subaccount;
    };

    let nameToken = "Motoko Bootcamp Token";
    let symbolToken = "MBT";

    let ledger : TrieMap.TrieMap<Account, Nat> = TrieMap.TrieMap(Account.accountsEqual, Account.accountsHash);

    public query func tokenName() : async Text {
        return nameToken;
    };

    public query func tokenSymbol() : async Text {
        return symbolToken;
    };

    public func mint(owner : Principal, amount : Nat) : async () {
        let defaultAccount = { owner = owner; subaccount = null };
        switch (ledger.get(defaultAccount)) {
            case (null) {
                ledger.put(defaultAccount, amount);
            };
            case (?some) {
                ledger.put(defaultAccount, some + amount);
            };
        };
        return;
    };

    public shared ({ caller }) func transfer(from : Account, to : Account, amount : Nat) : async Result<(), Text> {
        let fromBalance = switch (ledger.get(from)) {
            case (null) { 0 };
            case (?some) { some };
        };
        if (fromBalance < amount) {
            return #err("Not enough balance");
        };
        let toBalance = switch (ledger.get(to)) {
            case (null) { 0 };
            case (?some) { some };
        };
        ledger.put(from, fromBalance - amount);
        ledger.put(to, toBalance + amount);
        return #ok();
    };

    public query func balanceOf(account : Account) : async Nat {
        return switch (ledger.get(account)) {
            case (null) { 0 };
            case (?some) { some };
        };
    };

    public query func totalSupply() : async Nat {
        var total = 0;
        for (balance in ledger.vals()) {
            total += balance;
        };
        return total;
    };

    ///////////////
    // LEVEL #4 //
    /////////////

    public type Status = {
        #Open;
        #Accepted;
        #Rejected;
    };

    public type Proposal = {
        id : Nat;
        status : Status;
        manifest : Text;
        votes : Int;
        voters : [Principal];
    };

    public type CreateProposalOk = Nat;

    public type CreateProposalErr = {
        #NotDAOMember;
        #NotEnoughTokens;
    };

    public type createProposalResult = Result<CreateProposalOk, CreateProposalErr>;

    public type VoteOk = {
        #ProposalAccepted;
        #ProposalRefused;
        #ProposalOpen;
    };

    public type VoteErr = {
        #ProposalNotFound;
        #AlreadyVoted;
        #ProposalEnded;
        #NotDAOMember;
        #NotEnoughTokens;
    };

    public type voteResult = Result<VoteOk, VoteErr>;
    var proposalId : Nat = 0;
    let proposals : TrieMap.TrieMap<Nat, Proposal> = TrieMap.TrieMap(Nat.equal, Hash.hash);

    func _isMember(caller : Principal) : Bool {
        switch (dao.get(caller)) {
            case (null) { return false };
            case (?some) { return true };
        };
    };

    func _hasEnoughTokens(caller : Principal, necesaryAmount : Nat) : Bool {
        let defaultAccount = { owner = caller; subaccount = null };
        switch (ledger.get(defaultAccount)) {
            case (null) { return false };
            case (?some) { return some > necesaryAmount };
        };
    };
    
    func _burnTokens(caller : Principal, burnAmount : Nat) {
        let defaultAccount = { owner = caller; subaccount = null };
        switch (ledger.get(defaultAccount)) {
            case (null) { return };
            case (?some) { ledger.put(defaultAccount, some - burnAmount) };
        };
    };

    public shared ({ caller }) func createProposal(manifest : Text) : async createProposalResult {
        if (not _isMember(caller)) {
            return #err(#NotDAOMember);
        };
        if (not _hasEnoughTokens(caller, 1)) {
            return #err(#NotEnoughTokens);
        };
        let proposal = {
            id = proposalId;
            status = #Open;
            manifest = manifest;
            votes = 0;
            voters = [];
        };
        proposals.put(proposalId, proposal);
        proposalId += 1;
        _burnTokens(caller, 1);
        return #ok(proposal.id);
    };

    public query func getProposal(id : Nat) : async ?Proposal {
        proposals.get(id);
    };

    public shared ({ caller }) func vote(id : Nat, vote : Bool) : async voteResult {
        if (not _isMember(caller)) {
            return #err(#NotDAOMember);
        };
        if (not _hasEnoughTokens(caller, 1)) {
            return #err(#NotEnoughTokens);
        };
        let proposal = switch (proposals.get(id)) {
            case (null) { return #err(#ProposalNotFound) };
            case (?some) { some };
        };
        if (proposal.status != #Open) {
            return #err(#ProposalEnded);
        };
        for (voter in proposal.voters.vals()) {
            if (voter == caller) {
                return #err(#AlreadyVoted);
            };
        };
        let newVoters = Buffer.fromArray<Principal>(proposal.voters);
        newVoters.add(caller);
        let voteChange = if (vote == true) { 1 } else { -1 };
        let newVote = proposal.votes + voteChange;
        let newStatus = if (newVote >= 10) { #Accepted } else if (newVote <= -10) {
            #Rejected;
        } else { #Open };

        let newProposal : Proposal = {
            id = proposal.id;
            status = newStatus;
            manifest = proposal.manifest;
            votes = newVote;
            voters = Buffer.toArray(newVoters);
        };
        proposals.put(id, newProposal);
        _burnTokens(caller, 1);
        if (newStatus == #Accepted) {
            return #ok(#ProposalAccepted);
        };
        if (newStatus == #Rejected) {
            return #ok(#ProposalRefused);
        };
        return #ok(#ProposalOpen);
    };

    /// DO NOT REMOVE - Used for testing
    public shared query ({ caller }) func whoami() : async Principal {
        return caller;
    };

    ///////////////
    // LEVEL #5 //
    /////////////
    let logo : Text ="<svg width='100%' height='100%' viewBox='0 0 238 60' version='1.1' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' xml:space='preserve' style='fill-rule: evenodd; clip-rule: evenodd; stroke-linejoin: round; stroke-miterlimit: 2;'><path d='M92.561,7.748L92.561,26.642L87.959,26.642L87.959,15.984L83.572,26.642L80.154,26.642L75.767,15.984L75.767,26.642L71.165,26.642L71.165,7.748L76.44,7.748L81.877,20.775L87.286,7.748L92.561,7.748ZM99.64,24.085C97.774,22.255 96.841,19.94 96.841,17.141C96.841,14.342 97.778,12.032 99.653,10.211C101.528,8.39 103.825,7.479 106.543,7.479C109.262,7.479 111.549,8.39 113.406,10.211C115.264,12.032 116.192,14.342 116.192,17.141C116.192,19.94 115.259,22.255 113.393,24.085C111.527,25.915 109.239,26.83 106.53,26.83C103.821,26.83 101.524,25.915 99.64,24.085ZM110.136,21.098C111.051,20.111 111.509,18.792 111.509,17.141C111.509,15.491 111.056,14.172 110.15,13.185C109.244,12.198 108.033,11.705 106.516,11.705C105,11.705 103.789,12.198 102.883,13.185C101.977,14.172 101.524,15.491 101.524,17.141C101.524,18.792 101.977,20.111 102.883,21.098C103.789,22.085 105,22.578 106.516,22.578C108.033,22.578 109.239,22.085 110.136,21.098ZM119.206,11.247L119.206,7.748L134.117,7.748L134.117,11.247L128.949,11.247L128.949,26.642L124.347,26.642L124.347,11.247L119.206,11.247ZM139.903,24.085C138.037,22.255 137.104,19.94 137.104,17.141C137.104,14.342 138.042,12.032 139.917,10.211C141.792,8.39 144.088,7.479 146.807,7.479C149.525,7.479 151.813,8.39 153.67,10.211C155.527,12.032 156.456,14.342 156.456,17.141C156.456,19.94 155.522,22.255 153.656,24.085C151.79,25.915 149.503,26.83 146.793,26.83C144.084,26.83 141.787,25.915 139.903,24.085ZM150.4,21.098C151.315,20.111 151.772,18.792 151.772,17.141C151.772,15.491 151.319,14.172 150.413,13.185C149.507,12.198 148.296,11.705 146.78,11.705C145.264,11.705 144.053,12.198 143.146,13.185C142.24,14.172 141.787,15.491 141.787,17.141C141.787,18.792 142.24,20.111 143.146,21.098C144.053,22.085 145.264,22.578 146.78,22.578C148.296,22.578 149.503,22.085 150.4,21.098ZM165.364,26.642L160.762,26.642L160.762,7.748L165.364,7.748L165.364,16.038L171.608,7.748L177.637,7.748L169.859,17.195L177.637,26.642L171.716,26.642L165.364,18.299L165.364,26.642ZM183.181,24.085C181.315,22.255 180.382,19.94 180.382,17.141C180.382,14.342 181.32,12.032 183.195,10.211C185.07,8.39 187.366,7.479 190.085,7.479C192.803,7.479 195.091,8.39 196.948,10.211C198.805,12.032 199.733,14.342 199.733,17.141C199.733,19.94 198.8,22.255 196.934,24.085C195.068,25.915 192.781,26.83 190.071,26.83C187.362,26.83 185.065,25.915 183.181,24.085ZM193.678,21.098C194.593,20.111 195.05,18.792 195.05,17.141C195.05,15.491 194.597,14.172 193.691,13.185C192.785,12.198 191.574,11.705 190.058,11.705C188.542,11.705 187.33,12.198 186.424,13.185C185.518,14.172 185.065,15.491 185.065,17.141C185.065,18.792 185.518,20.111 186.424,21.098C187.33,22.085 188.542,22.578 190.058,22.578C191.574,22.578 192.781,22.085 193.678,21.098Z' style='fill: rgb(10, 12, 24);'></path><path d='M71.165,32.834L79.374,32.834C81.293,32.834 82.823,33.301 83.962,34.234C85.102,35.167 85.671,36.351 85.671,37.787C85.671,39.922 84.424,41.366 81.93,42.12C83.204,42.299 84.218,42.829 84.972,43.708C85.725,44.587 86.102,45.619 86.102,46.803C86.102,48.31 85.55,49.508 84.447,50.396C83.343,51.284 81.805,51.728 79.831,51.728L71.165,51.728L71.165,32.834ZM75.767,36.333L75.767,40.424L78.781,40.424C79.445,40.424 79.979,40.254 80.383,39.913C80.787,39.572 80.988,39.065 80.988,38.392C80.988,37.719 80.787,37.208 80.383,36.858C79.979,36.508 79.445,36.333 78.781,36.333L75.767,36.333ZM75.767,48.229L79.239,48.229C79.867,48.229 80.387,48.041 80.8,47.664C81.213,47.287 81.419,46.767 81.419,46.103C81.419,45.439 81.222,44.91 80.827,44.515C80.432,44.12 79.921,43.923 79.293,43.923L75.767,43.923L75.767,48.229ZM92.346,49.171C90.48,47.341 89.547,45.027 89.547,42.227C89.547,39.428 90.485,37.118 92.36,35.297C94.235,33.476 96.531,32.565 99.25,32.565C101.968,32.565 104.256,33.476 106.113,35.297C107.97,37.118 108.898,39.428 108.898,42.227C108.898,45.027 107.965,47.341 106.099,49.171C104.233,51.001 101.946,51.917 99.236,51.917C96.527,51.917 94.23,51.001 92.346,49.171ZM102.843,46.184C103.758,45.197 104.215,43.878 104.215,42.227C104.215,40.577 103.762,39.258 102.856,38.271C101.95,37.284 100.739,36.791 99.223,36.791C97.707,36.791 96.495,37.284 95.589,38.271C94.683,39.258 94.23,40.577 94.23,42.227C94.23,43.878 94.683,45.197 95.589,46.184C96.495,47.171 97.707,47.664 99.223,47.664C100.739,47.664 101.946,47.171 102.843,46.184ZM114.9,49.171C113.034,47.341 112.101,45.027 112.101,42.227C112.101,39.428 113.039,37.118 114.914,35.297C116.789,33.476 119.085,32.565 121.804,32.565C124.522,32.565 126.81,33.476 128.667,35.297C130.524,37.118 131.452,39.428 131.452,42.227C131.452,45.027 130.519,47.341 128.653,49.171C126.787,51.001 124.5,51.917 121.79,51.917C119.081,51.917 116.784,51.001 114.9,49.171ZM125.397,46.184C126.312,45.197 126.769,43.878 126.769,42.227C126.769,40.577 126.316,39.258 125.41,38.271C124.504,37.284 123.293,36.791 121.777,36.791C120.261,36.791 119.049,37.284 118.143,38.271C117.237,39.258 116.784,40.577 116.784,42.227C116.784,43.878 117.237,45.197 118.143,46.184C119.049,47.171 120.261,47.664 121.777,47.664C123.293,47.664 124.5,47.171 125.397,46.184ZM134.467,36.333L134.467,32.834L149.377,32.834L149.377,36.333L144.21,36.333L144.21,51.728L139.607,51.728L139.607,36.333L134.467,36.333ZM155.164,49.171C153.298,47.341 152.365,45.027 152.365,42.227C152.365,39.428 153.302,37.118 155.177,35.297C157.052,33.476 159.344,32.565 162.054,32.565C164.153,32.565 166.019,33.122 167.652,34.234C169.285,35.346 170.424,36.89 171.07,38.863L165.579,38.863C164.862,37.482 163.713,36.791 162.134,36.791C160.555,36.791 159.313,37.284 158.407,38.271C157.501,39.258 157.048,40.577 157.048,42.227C157.048,43.878 157.501,45.197 158.407,46.184C159.313,47.171 160.555,47.664 162.134,47.664C163.713,47.664 164.862,46.973 165.579,45.592L171.07,45.592C170.424,47.565 169.285,49.109 167.652,50.221C166.019,51.333 164.153,51.89 162.054,51.89C159.344,51.89 157.048,50.984 155.164,49.171ZM187.38,51.728L186.33,48.552L179.548,48.552L178.498,51.728L173.6,51.728L180.167,32.781L185.765,32.781L192.305,51.728L187.38,51.728ZM180.705,45.053L185.173,45.053L182.939,38.325L180.705,45.053ZM217.308,32.834L217.308,51.728L212.706,51.728L212.706,41.07L208.319,51.728L204.901,51.728L200.514,41.07L200.514,51.728L195.912,51.728L195.912,32.834L201.187,32.834L206.623,45.861L212.033,32.834L217.308,32.834ZM237.09,38.621C237.09,39.895 236.633,41.124 235.717,42.308C235.233,42.918 234.511,43.416 233.551,43.802C232.591,44.188 231.456,44.381 230.146,44.381L227.293,44.381L227.293,51.728L222.691,51.728L222.691,32.834L230.146,32.834C232.335,32.834 234.04,33.4 235.26,34.53C236.48,35.66 237.09,37.024 237.09,38.621ZM227.293,40.882L230.146,40.882C230.846,40.882 231.398,40.675 231.801,40.263C232.205,39.85 232.407,39.307 232.407,38.634C232.407,37.962 232.201,37.41 231.788,36.979C231.375,36.549 230.828,36.333 230.146,36.333L227.293,36.333L227.293,40.882Z' style='fill: rgb(10, 12, 24);'></path><path d='M50.702,8.694C39.11,-2.898 20.287,-2.898 8.694,8.694C-2.898,20.287 -2.898,39.11 8.694,50.702C20.286,62.294 39.109,62.294 50.702,50.702C62.294,39.109 62.294,20.286 50.702,8.694Z' style='fill: rgb(10, 12, 24);'></path><path d='M47.507,11.889C37.678,2.06 21.718,2.06 11.889,11.889C2.06,21.718 2.06,37.678 11.889,47.507C21.718,57.336 37.678,57.336 47.507,47.507C57.336,37.678 57.336,21.718 47.507,11.889Z' style='fill: rgb(250, 232, 78);'></path><path d='M26.129,15.163C31.125,10.167 39.237,10.167 44.233,15.163C49.229,20.159 49.229,28.271 44.233,33.267L30.463,47.037C29.681,47.819 28.483,48.005 27.5,47.498C26.518,46.99 25.976,45.905 26.162,44.815L26.163,44.811C26.314,43.923 25.939,43.028 25.201,42.513C24.463,41.997 23.494,41.954 22.712,42.401L18.689,44.704C17.542,45.361 16.097,45.168 15.163,44.233C14.228,43.298 14.035,41.854 14.692,40.707L16.981,36.707C17.429,35.925 17.384,34.955 16.866,34.217C16.348,33.48 15.45,33.108 14.563,33.264L14.558,33.265C13.466,33.457 12.377,32.919 11.866,31.936C11.354,30.954 11.539,29.753 12.323,28.969L26.129,15.163Z' style='fill: rgb(10, 12, 24);'></path><path d='M28.538,18.472C24.617,22.393 24.209,28.352 27.627,31.77C31.045,35.188 37.004,34.78 40.925,30.859C44.846,26.937 45.255,20.979 41.836,17.56C38.418,14.142 32.459,14.55 28.538,18.472Z' style='fill: rgb(255, 255, 255);'></path><path d='M37.061,19.582C36.301,20.342 36.301,21.576 37.061,22.336C37.82,23.095 39.054,23.095 39.814,22.336C40.574,21.576 40.574,20.342 39.814,19.582C39.054,18.822 37.82,18.822 37.061,19.582Z' style='fill: rgb(10, 12, 24);'></path><path d='M31.217,25.425C30.457,26.185 30.457,27.419 31.217,28.179C31.977,28.939 33.21,28.939 33.971,28.18C34.731,27.42 34.731,26.186 33.971,25.426C33.211,24.666 31.977,24.666 31.217,25.425Z' style='fill: rgb(10, 12, 24);'></path></svg>";
    func _getWebpage() : Text {
        var webpage = "<style>" #
        "body { text-align: center; font-family: Arial, sans-serif; background-color: #f0f8ff; color: #333; }" #
        "h1 { font-size: 3em; margin-bottom: 10px; }" #
        "hr { margin-top: 20px; margin-bottom: 20px; }" #
        "em { font-style: italic; display: block; margin-bottom: 20px; }" #
        "ul { list-style-type: none; padding: 0; }" #
        "li { margin: 10px 0; }" #
        "li:before { content: '?? '; }" #
        "svg { max-width: 150px; height: auto; display: block; margin: 20px auto; }" #
        "h2 { text-decoration: underline; }" #
        "</style>";

        webpage := webpage # "<div><h1>" # name # "</h1></div>";
        webpage := webpage # "<em>" # manifesto # "</em>";
        webpage := webpage # "<div>" # logo # "</div>";
        webpage := webpage # "<hr>";
        webpage := webpage # "<h2>Our goals:</h2>";
        webpage := webpage # "<ul>";
        for (goal in goals.vals()) {
            webpage := webpage # "<li>" # goal # "</li>";
        };
        webpage := webpage # "</ul>";
        return webpage;
    };

    public type DAOStats = {
        name : Text;
        manifesto : Text;
        goals : [Text];
        member : [Text];
        logo : Text;
        numberOfMembers : Nat;
    };
    public type HttpRequest = Http.Request;
    public type HttpResponse = Http.Response;

    public query func http_request(request : HttpRequest) : async HttpResponse {
        return ({
            status_code = 200;
            headers = [("Content-Type","text/html;charset=UTF-8")];
            body = Text.encodeUtf8(_getWebpage());
            streaming_strategy = null;
        });
    };

    func _getNameFromMember (member : Member) : Text {
        return member.name;
    };

    public query func getStats() : async DAOStats {
        return ({
            name = name;
            manifesto = manifesto;
            goals = Buffer.toArray(goals);
            member = Iter.toArray(Iter.map(dao.vals(),_getNameFromMember));
            logo = logo;
            numberOfMembers = dao.size();
        });
    };

};