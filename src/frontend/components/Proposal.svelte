<script>
  export let post
</script>

<div class="post-preview">
  <h2>{(post.id / BigInt(100000000)).toString()} {post.manifest}</h2>
 <p>
  Votes Status: {(parseInt(post.votes)).toString()}
</p>
<p>
  Voters: {(post.voters.length).toString()}
</p>
</div>

<style>
  .post-preview {
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
