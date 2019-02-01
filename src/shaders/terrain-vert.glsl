#version 300 es
precision highp float;

uniform mat4 u_Model;
uniform mat4 u_ModelInvTr;
uniform mat4 u_ViewProj;
uniform vec2 u_PlanePos; // Our location in the virtual world displayed by the plane
uniform float u_BiomeSize;
uniform float u_AvgTemp;
uniform float u_AvgRain;

in vec4 vs_Pos;
in vec4 vs_Nor;
in vec4 vs_Col;

out vec3 fs_Pos;
out vec4 fs_Nor;
out vec4 fs_Col;

out float fs_Height;
out float fs_RainMixAmount;
out float fs_TempMixAmount;

float random1(vec2 p, vec2 seed) {
  return fract(sin(dot(p + seed, vec2(127.1, 311.7))) * 43758.5453);
}

float random1(vec3 p, vec3 seed) {
  return fract(sin(dot(p + seed, vec3(987.654, 123.456, 531.975))) * 85734.3545);
}

vec2 random2(vec2 p, vec2 seed) {
  return fract(sin(vec2(dot(p + seed, vec2(311.7, 127.1)), dot(p + seed, vec2(269.5, 183.3)))) * 85734.3545);
}

vec2 randvec1(vec2 n, vec2 seed) {
    float x = sin(dot(n + seed, vec2(131.32, 964.31)));
    float y = sin(dot(n + seed, vec2(139.345, 132.89)));
    vec2 v = fract(329.779f * vec2(x, y));
    return vec2(2.0 * v.x - 1.0, 2.0 * v.y - 1.0);
}

vec2 randvec2(vec2 n, vec2 seed) {
    float x = sin(dot(n + seed, vec2(113.2, 634.11)));
    float y = sin(dot(n + seed, vec2(109.5, 242.8)));
    return fract(3242.177f * vec2(x, y));
}

vec2 randvec3(vec2 n, vec2 seed) {
  float x = sin(dot(n + seed, vec2(14.92, 64.42)));
  float y = sin(dot(n + seed, vec2(48.12, 32.42)));
  return fract(334.963f * vec2(x, y));
}

float quinticSmooth(float t) {
  float x = clamp(t, 0.0, 1.0);
  return x * x * x * (x * (x * 6.0  - 15.0) + 10.0);
}

float perlinNoise(float x, float z) {
  float gridWidth = 20.0;
  vec2 seed = vec2(0.0, 0.0);

  vec2 pos = vec2(x, z);
  vec2 corner1 = vec2(gridWidth * floor(x / gridWidth), gridWidth * floor(z / gridWidth));
  vec2 corner2 = vec2(corner1.x + gridWidth, corner1.y);
  vec2 corner3 = vec2(corner1.x + gridWidth, corner1.y + gridWidth);
  vec2 corner4 = vec2(corner1.x, corner1.y + gridWidth);

  if (length(pos - corner1) == 0.0) {
    corner1 += vec2(-0.01, -0.01);
  } else if (length(pos - corner2) == 0.0) {
    corner2 += vec2(0.01, -0.01);
  } else if (length(pos - corner3) == 0.0) {
    corner3 += vec2(0.01, 0.01);
  } else if (length(pos - corner4) == 0.0) {
    corner4 += vec2(-0.01, 0.01);
  }

  vec2 normalize1 = vec2(1.0, 0.0);
  vec2 normalize2 = vec2(1.0, 0.0);
  vec2 normalize3 = vec2(1.0, 0.0);
  vec2 normalize4 = vec2(1.0, 0.0);
  if (length(random2(corner1, seed)) != 0.0) {
    normalize1 = normalize(randvec1(corner1, seed));
  }
  if (length(random2(corner2, seed)) != 0.0) {
    normalize2 = normalize(randvec1(corner2, seed));
  }
  if (length(random2(corner3, seed)) != 0.0) {
    normalize3 = normalize(randvec1(corner3, seed));
  }
  if (length(random2(corner4, seed)) != 0.0) {
    normalize4 = normalize(randvec1(corner4, seed));
  }

  float dot1 = dot(normalize1, normalize(pos - corner1));
  float dot2 = dot(normalize2, normalize(pos - corner2));
  float dot3 = dot(normalize3, normalize(pos - corner3));
  float dot4 = dot(normalize4, normalize(pos - corner4));

  float fractX = vec2(pos - corner1).x / gridWidth;
  float fractY = vec2(pos - corner1).y / gridWidth;

  float i1 = mix(dot1, dot2, quinticSmooth(fractX));
  float i2 = mix(dot4, dot3, quinticSmooth(fractX));

  return mix(i1, i2, quinticSmooth(fractY));
}

float interpRand(float x, float z) {
  vec2 seed = vec2(0.0, 0.0);

  float intX = floor(x);
  float fractX = fract(x);
  float intZ = floor(z);
  float fractZ = fract(z);

  vec2 c1 = vec2(intX, intZ);
  vec2 c2 = vec2(intX + 1.0, intZ);
  vec2 c3 = vec2(intX, intZ + 1.0);
  vec2 c4 = vec2(intX + 1.0, intZ + 1.0);

  float v1 = random1(c1, seed);
  float v2 = random1(c2, seed);
  float v3 = random1(c3, seed);
  float v4 = random1(c4, seed);

  float i1 = mix(v1, v2, quinticSmooth(fractX));
  float i2 = mix(v3, v4, quinticSmooth(fractX));
  return mix(i1, i2, quinticSmooth(fractZ));
}

float worleyNoise(vec2 pos) {
  float factor = 8.0;
  vec2 seed = vec2(0.0, 0.0);

  int x = int(floor(pos.x / factor));
  int y = int(floor(pos.y / factor));
  vec2 minWorley = factor * randvec3(vec2(float(x), float(y)), seed) + vec2(float(x) * factor, float(y) * factor);
  float minDist = distance(minWorley, pos);
  for (int i = x - 1; i <= x + 1; i++) {
      for (int j = y - 1; j <= y + 1; j++) {
          vec2 worley = factor * randvec3(vec2(float(i), float(j)), seed) + vec2(float(i) * factor, float(j) * factor);
          if (minDist > distance(pos, worley)) {
              minDist = distance(pos, worley);
              minWorley = worley;
          }
      }
  }
  return clamp(minDist / (factor * 2.0), 0.0, 0.5);
}

float fbmHeight(float x, float z, float biome, int octaves) {
  float total = 0.0;
  for (int i = 0; i < octaves; i++) {
    if (biome < 0.5) {
      float persistence = 0.5f;
      float freq = pow(2.0, float(i));
      float amp = pow(persistence, float(i));
      total += interpRand(x / 10.0 * freq, z / 10.0 * freq) * amp;
    } else if (biome >= 0.5 && biome < 1.5) {
      float persistence = 0.25f;
      float freq = pow(2.0, float(i));
      float amp = pow(persistence, float(i));
      total += perlinNoise(x * freq, z * freq) * amp;
    } else if (biome >= 1.5 && biome < 2.5) {
      float persistence = 0.6;
      float freq = pow(2.0, float(i));
      float amp = pow(persistence, float(i));
      total += interpRand(x / 5.0 * freq, z / 5.0 * freq) * amp;
    } else if (biome >= 2.5) {
      float persistence = 0.7;
      float freq = pow(2.0, float(i));
      float amp = pow(persistence, float(i));
      total += worleyNoise(vec2(x * freq, z * freq)) * amp;
    }
  }
  return total;
}

vec2 biome(float x, float z) {
  vec2 seed = vec2(0.0, 0.0);

  float intX = floor(x);
  float fractX = fract(x);
  float intZ = floor(z);
  float fractZ = fract(z);

  vec2 c1 = vec2(intX, intZ);
  vec2 c2 = vec2(intX + 1.0, intZ);
  vec2 c3 = vec2(intX, intZ + 1.0);
  vec2 c4 = vec2(intX + 1.0, intZ + 1.0);

  vec2 v1 = random2(c1, seed);
  vec2 v2 = random2(c2, seed);
  vec2 v3 = random2(c3, seed);
  vec2 v4 = random2(c4, seed);

  vec2 i1 = mix(v1, v2, quinticSmooth(fractX));
  vec2 i2 = mix(v3, v4, quinticSmooth(fractX));
  return mix(i1, i2, quinticSmooth(fractZ));
}

vec2 tempAndRainfall(vec2 pos) {
  vec2 total =  vec2(0.0, 0.0);
  float persistence = 0.5f;
  int octaves = 8;

  for (int i = 0; i < octaves; i++) {
    float freq = pow(2.0, float(i));
    float amp = pow(persistence, float(i));
    total += biome(pos.x * freq / u_BiomeSize, pos.y * freq / u_BiomeSize) * amp;
  }
  return clamp(total / 2.0, 0.0, 1.0);
}

float bias(float b, float t) {
  return pow(t, log(b) / log(0.5));
}

float gain(float g, float t) {
  if (t < 0.5) {
    return bias(1.0 - g, 2.0 * t) / 2.0;
  } else {
    return 1.0 - bias(1.0 - g, 2.0 - 2.0 * t) / 2.0;
  }
}

void main()
{
  fs_Pos = vs_Pos.xyz;

  float x = vs_Pos.x + u_PlanePos.x;
  float z = vs_Pos.z + u_PlanePos.y;

  float tundraHeight = fbmHeight(x, z, 0.0, 8);
  float mountainsHeight = fbmHeight(x, z, 1.0, 8) * 15.0;
  vec2 q = vec2(fbmHeight(x, z, 2.0, 8), fbmHeight(x + 5.2, z + 1.3, 2.0, 8));
  float desertHeight = fbmHeight(x + 4.0 * q.x, z + 4.0 * q.y, 2.0, 8) * 2.0;
  float forestHeight = bias(0.7, fbmHeight(x, z, 3.0, 4)) * 7.0;

  vec2 biomeAttr = tempAndRainfall(vec2(x, z));
  fs_TempMixAmount = gain(0.9999, clamp(biomeAttr.x + u_AvgTemp - 0.5, 0.0, 1.0));
  fs_RainMixAmount = gain(0.9999, clamp(biomeAttr.y + u_AvgRain - 0.5, 0.0, 1.0));
  float heightX1 = mix(tundraHeight, desertHeight, fs_TempMixAmount);
  float heightX2 = mix(mountainsHeight, forestHeight, fs_TempMixAmount);
  fs_Height = mix(heightX1, heightX2, fs_RainMixAmount);

  vec4 modelposition = vec4(vs_Pos.x, fs_Height, vs_Pos.z, 1.0);
  modelposition = u_Model * modelposition;
  gl_Position = u_ViewProj * modelposition;
}
