#version 300 es

precision mediump float;

// The object ID output is turned into a "color" that will be sampled with
// glReadPixels() later. See Renderer.handle_click().
out uint outObjectId;

// The object ID is provided by the Renderer during rendering. This shader
// is just saving the value to a custom framebuffer so we can examine the
// visible object under the cursor.
uniform uint inObjectId;

void main() {
    outObjectId = inObjectId;
}