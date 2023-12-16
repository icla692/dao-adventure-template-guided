<script>
  import { view } from '../stores.js';
  import { canisterId as canisterIdBackend } from '../../declarations/backend/index.js';
  import { AuthClient } from '@dfinity/auth-client';
  import { HttpAgent } from '@dfinity/agent';
  import { principal } from '../stores';
  import { daoActor } from '../stores';

  const handleView = () => {
    $view.current = $view.view;
  };
  const handleCreate = () => {
    $view.current = $view.create;
  };
  const handleVote = () => {
    $view.current = $view.vote;
  };
  const handleHome = () => {
    $view.current = $view.home;
  };

  const canisterId = "axuxn-2qaaa-aaaap-aav6q-cai";

  const handleWebpage = () => {
    process.env.DFX_NETWORK === 'ic'
      ? window.open(`https://${canisterId}.raw.icp0.io`, '_blank')
      : window.open(
          `http://localhost:4943/?canisterId=${canisterIdBackend}`,
          '_blank',
        );
  };

  const handleLogin = async () => {
    let authClient = await AuthClient.create();
    const identityProvider =
      process.env.DFX_NETWORK === 'ic'
        ? 'https://identity.ic0.app'
        : `http://127.0.0.1:4943/?canisterId=${process.env.CANISTER_ID_INTERNET_IDENTITY}`;

    await authClient?.login({
      onSuccess: () => {
        resolve();
      },
      identityProvider,
    });
    const p = authClient.getIdentity().getPrincipal();
    principal.set(p);
    const agent = new HttpAgent({ identity });
    const actor = reateActor(canisterIdBackend, {
      agent,
    });
    daoActor.set(actor);
  };
</script>

<nav>
  <ul>
    <li on:click={() => handleHome()}>🏠 Home</li>
    <li on:click={() => handleView()}>🚀 View</li>
    <li on:click={() => handleCreate()}>⭐️ Create</li>
    <li on:click={() => handleVote()}>🗑 Vote</li>
  </ul>
  <div class="buttons">
    <button on:click={() => handleWebpage()}> Webpage </button>
    <button on:click={() => handleLogin()}> Login </button>
  </div>
</nav>

<style>
  nav {
    min-height: 100vh;
    background-color: #262626;
    color: #a2b7c4;
    transition: ease-out 200ms;
    width: 20vmin;
    position: relative;
  }

  ul {
    list-style: none;
    padding-left: 1vmin;
    padding-right: 1vmin;
    margin: 0;
    margin-top: 2vmin;
  }

  li {
    width: 100%;
    padding-top: 2vmin;
    padding-bottom: 2vmin;
    display: flex;
    flex-direction: column;
    justify-content: center;
    font-weight: 600;
    font-size: 1em;
    cursor: pointer;
  }

  li:hover {
    background-color: #6e6b6b;
    transition: 300ms;
    transform: scale(1.08);
  }

  .buttons {
    display: flex;
    flex-direction: column;
    align-items: center;
  }
</style>
