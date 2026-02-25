export default {
  async fetch(request, env) {
    // Only allow GET requests
    if (request.method !== "GET") {
      return new Response("Method not allowed", { status: 405 });
    }

    const url = new URL(request.url);

    // Only proxy the video search endpoint
    if (url.pathname !== "/videos/search") {
      return new Response("Not found", { status: 404 });
    }

    const pexelsURL = `https://api.pexels.com/videos/search${url.search}`;

    const resp = await fetch(pexelsURL, {
      headers: { Authorization: env.PEXELS_API_KEY },
    });

    return new Response(resp.body, {
      status: resp.status,
      headers: { "Content-Type": "application/json" },
    });
  },
};
