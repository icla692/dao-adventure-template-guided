<script>
  import Proposal from './Proposal.svelte';
  import { get } from 'svelte/store';
  import { daoActor, principal } from '../stores';

  async function get_all_proposals() {
    let dao = get(daoActor);
    if (!dao) {
      return;
    }
    console.log('Principal', principal);
    let res = await dao.getProposals();
    console.log('Proposals', res);
    return res;
  }
  let promise = get_all_proposals();
</script>

{#if $principal}
  {#await promise}
    <p>Loading...</p>
  {:then proposals}
    <div id="proposals">
      <h1>Proposals</h1>
      {#each proposals as post}
        <Proposal {post} />
      {/each}
    </div>
  {:catch error}
    <p style="color: red">{error.message}</p>
  {/await}
{:else}
  <p class="example-disabled">Login to access this page</p>
{/if}

<style>
  h1 {
    color: white;
    font-size: 10vmin;
    font-weight: 700;
  }

  #proposals {
    display: flex;
    flex-direction: column;
    width: 100%;
    margin-left: 10vmin;
  }
</style>
