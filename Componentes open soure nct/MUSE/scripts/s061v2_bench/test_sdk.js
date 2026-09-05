const Anthropic = require('@anthropic-ai/sdk');

const anthropic = new Anthropic({
    apiKey: process.env.ANTHROPIC_API_KEY
});

async function main() {
    const models = [
        "claude-3-7-sonnet-20250219",
        "claude-3-5-sonnet-20241022",
        "claude-3-5-sonnet-20240620",
        "claude-3-sonnet-20240229",
        "claude-3-5-haiku-20241022",
        "claude-3-haiku-20240307"
    ];

    for (const model of models) {
        try {
            console.log(`Testing ${model}...`);
            const msg = await anthropic.messages.create({
                model: model,
                max_tokens: 10,
                messages: [{ role: "user", content: "Hi" }]
            });
            console.log(`✅ Success with ${model}:`, msg.content[0].text);
            return; // Exit on first success
        } catch (err) {
            console.log(`❌ Failed ${model}:`, err.message);
        }
    }
}
main();
