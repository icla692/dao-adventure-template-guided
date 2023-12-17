<script>
  import logo from ".././assets/camp_logo.png"
  import { Principal } from '@dfinity/principal';
  import { get } from 'svelte/store';
  import { daoActor, principal } from '../stores';

  let principalId = '';
  let age = '';

  // async function get_all_members() {
  //   let dao = get(daoActor);
  //   if (!dao) {
  //     return;
  //   }
  //   console.log('Principal', principal);
  //   let res = await dao.getMembers();
  //   console.log('Proposals', res);
  //   return res;
  // }
  // let promise = get_all_proposals();


  async function addMember() {
    if (!principalId || !age || isNaN(age)) {
      alert('Please enter valid information');
      return;
    }

    let dao = get(daoActor);
    if (!dao) {
      return;
    }

    let res = await dao.addMember(BigInt(age),principalId);

    // Reset the form fields after adding the member
    principalId = '';
    age = '';
  };
</script>

<div class="member-preview">
  <h2>Add Member</h2>
  <form on:submit|preventDefault={addMember}>
    <label for="principalId">Principal ID:</label>
    <input type="text" bind:value={principalId} id="principalId" />

    <label for="age">Age:</label>
    <input type="text" bind:value={age} id="age" />

    <button type="submit">Add Member</button>
  </form>
</div>



<style>
  .member-preview {
    border: 1px solid white;
    border-radius: 10px;
    margin-bottom: 2vmin;
    padding: 2vmin;
  }
  h2 {
    color: rgb(8, 8, 8);
  }

  p {
    color: rgb(26, 25, 25);
  }

</style>
<!-- <div>
  <h2>Members</h2>
    {#if members.length > 0}
      <table>
        <thead>
          <tr>
            <th>Principal ID</th>
            <th>Age</th>
          </tr>
        </thead>
        <tbody>
          {#each members as member (member.principalId)}
            <tr>
              <td>{member.principalId}</td>
              <td>{member.age}</td>
            </tr>
          {/each}
        </tbody>
      </table>
    {:else}
      <p>No members yet.</p>
    {/if}
</div> -->
