#version 300 es
precision highp float;

uniform vec2 u_PlanePos; // Our location in the virtual world displayed by the plane

in vec3 fs_Pos;
in vec4 fs_Nor;
in vec4 fs_Col;

in float fs_Height;
in float fs_RainMixAmount;
in float fs_TempMixAmount;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

vec4 tundraCol() {
  float t = clamp(smoothstep(40.0, 50.0, length(fs_Pos)), 0.0, 1.0); // Distance fog
  float snow = smoothstep(0.5, 1.0, clamp(fs_Height, 0.5, 1.0));
  return vec4(mix(mix(vec3(0.25, 0.25, 0.25), vec3(1.0, 1.0, 1.0), snow), vec3(164.0 / 255.0, 233.0 / 255.0, 1.0), t), 1.0);
}

vec4 mountainsCol() {
  float t = clamp(smoothstep(40.0, 50.0, length(fs_Pos)), 0.0, 1.0); // Distance fog
  if (fs_Height < 0.01) {
    return vec4(mix(vec3(0.0, 0.0, 1.0), vec3(164.0 / 255.0, 233.0 / 255.0, 1.0), t), 1.0);
  } else if (fs_Height < 6.0) {
    return vec4(mix(vec3(0.0, 0.5, 0.0), vec3(164.0 / 255.0, 233.0 / 255.0, 1.0), t), 1.0);
  } else {
    float snow = smoothstep(6.0, 12.0, clamp(fs_Height, 6.0, 12.0));
    return vec4(mix(mix(vec3(0.0, 0.5, 0.0), vec3(1.0, 1.0, 1.0), snow), vec3(164.0 / 255.0, 233.0 / 255.0, 1.0), t), 1.0);
  }
}

vec4 desertCol() {
  float t = clamp(smoothstep(40.0, 50.0, length(fs_Pos)), 0.0, 1.0); // Distance fog
  float re = fs_Height + fs_Pos.x + u_PlanePos.x + fs_Pos.z + u_PlanePos.y - 5.0 * floor((fs_Height + fs_Pos.x + u_PlanePos.x + fs_Pos.z + u_PlanePos.y) / 5.0);
  float dune = smoothstep(0.0, 5.0, re);
  return vec4(mix(mix(vec3(0.929, 0.788, 0.686), vec3(0.588, 0.443, 0.090), dune), vec3(164.0 / 255.0, 233.0 / 255.0, 1.0), t), 1.0);
}

vec4 forestCol() {
  float t = clamp(smoothstep(40.0, 50.0, length(fs_Pos)), 0.0, 1.0); // Distance fog
  float green = smoothstep(0.0, 7.5, clamp(fs_Height, 0.0, 7.5));
  return vec4(mix(mix(vec3(0.5, 1.0, 0.0), vec3(0.133, 0.545, 0.133), green), vec3(164.0 / 255.0, 233.0 / 255.0, 1.0), t), 1.0);
}

void main()
{
  vec4 tundraCol = tundraCol();
  vec4 mountainsCol = mountainsCol();
  vec4 desertCol = desertCol();
  vec4 forestCol = forestCol();
  vec4 colX1 = mix(tundraCol, desertCol, fs_TempMixAmount);
  vec4 colX2 = mix(mountainsCol, forestCol, fs_TempMixAmount);
  out_Col = mix(colX1, colX2, fs_RainMixAmount);
}
