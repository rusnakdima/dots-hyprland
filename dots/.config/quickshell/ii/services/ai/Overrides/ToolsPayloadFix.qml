/**
 * ToolsPayloadFix — fork override
 *
 * Problem: When currentModelHasTools === false, some strict-validator providers
 * (Cloudflare Workers AI, Mistral, and others) reject payloads that include
 * an empty tools: [] array. The OpenAI API strategy sends tools: [] regardless.
 *
 * Fix: When Config.options.ai.tool is "none" or empty, omit the tools key
 * entirely from the request payload.
 *
 * This override patches ApiStrategy.buildRequestData to conditionally exclude
 * the tools field when no tools are available.
 */

import QtQuick

ApiStrategy {
    property bool _toolsPayloadFix_applied: false

    function buildRequestData(model, messages, systemPrompt, temperature, tools, filePath) {
        // Check if tools should be omitted
        const toolOption = Config.options?.ai?.tool ?? "functions"
        const shouldOmitTools = (toolOption === "none" || toolOption === "")

        if (shouldOmitTools) {
            // Build base data WITHOUT the tools key
            let baseData = {
                "model": model.model,
                "messages": [
                    { role: "system", content: systemPrompt },
                    ...messages.map(message => {
                        return {
                            "role": message.role,
                            "content": message.rawContent,
                        }
                    }),
                ],
                "stream": true,
                "temperature": temperature,
            };
            return model.extraParams ? Object.assign({}, baseData, model.extraParams) : baseData;
        }

        // Fall back to original behavior
        let baseData = {
            "model": model.model,
            "messages": [
                { role: "system", content: systemPrompt },
                ...messages.map(message => {
                    return {
                        "role": message.role,
                        "content": message.rawContent,
                    }
                }),
            ],
            "stream": true,
            "tools": tools,
            "temperature": temperature,
        };
        return model.extraParams ? Object.assign({}, baseData, model.extraParams) : baseData;
    }
}
