#version 300 es
precision highp float;

uniform vec2 u_PlanePos; // Our location in the virtual world displayed by the plane

in vec3 fs_Pos;
in vec4 fs_Nor;
in vec4 fs_Col;

in float fs_Biome;
in float fs_Height;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

void main()
{
    float t = clamp(smoothstep(40.0, 50.0, length(fs_Pos)), 0.0, 1.0); // Distance fog
    int biome = int(fs_Biome);
    if (biome == 0) {
      float snow = smoothstep(0.0, 0.5, clamp(fs_Height, 0.0, 0.5));
      out_Col = vec4(mix(mix(vec3(0.25, 0.25, 0.25), vec3(1.0, 1.0, 1.0), snow), vec3(164.0 / 255.0, 233.0 / 255.0, 1.0), t), 1.0);
    } else if (biome == 1) {
      if (fs_Height < 0.01) {
        out_Col = vec4(mix(vec3(0.0, 0.0, 1.0), vec3(164.0 / 255.0, 233.0 / 255.0, 1.0), t), 1.0);
      } else if (fs_Height < 2.0) {
        out_Col = vec4(mix(vec3(0.0, 0.5, 0.0), vec3(164.0 / 255.0, 233.0 / 255.0, 1.0), t), 1.0);
      } else {
        float snow = smoothstep(0.5, 1.0, clamp(fs_Height, 0.5, 1.0));
        out_Col = vec4(mix(mix(vec3(0.0, 0.5, 0.0), vec3(1.0, 1.0, 1.0), snow), vec3(164.0 / 255.0, 233.0 / 255.0, 1.0), t), 1.0);
      }
    }
}
