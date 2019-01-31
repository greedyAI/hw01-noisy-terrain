#version 300 es
precision highp float;

uniform mat4 u_Model;
uniform mat4 u_ModelInvTr;
uniform mat4 u_ViewProj;
uniform vec2 u_PlanePos; // Our location in the virtual world displayed by the plane

in vec4 vs_Pos;
in vec4 vs_Nor;
in vec4 vs_Col;

out vec3 fs_Pos;
out vec4 fs_Nor;
out vec4 fs_Col;

out float fs_Biome;
out float fs_Height;

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

float quinticSmooth(float t) {
  return t * t * t * (t * (t * 6.0  - 15.0) + 10.0);
}

float perlinNoise(float x, float z) {
  float gridWidth = 10.0;
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

float fbmHeight(float x, float z, int biome) {
  float total = 0.0;
  float persistence = 0.25f;
  int octaves = 8;

  for (int i = 0; i < octaves; i++) {
    float freq = pow(2.0, float(i));
    float amp = pow(persistence, float(i));
    if (biome == 0) {
      total += perlinNoise(x * freq, z * freq) * amp;
    } else if (biome == 1) {
      total += interpRand(x * freq, z * freq) * amp;
    }
  }
  return total;
}

vec2 tempAndRainfall(vec2 pos) {
    float factor = 256.0;
    vec2 seed = vec2(0.0, 0.0);

    int x = int(floor(pos.x / factor));
    int y = int(floor(pos.y / factor));
    vec2 minWorley = factor * randvec2(pos, seed) + vec2(float(x) * factor, float(y) * factor);
    float minDist = distance(minWorley, pos);
    for (int i = x - 1; i <= x + 1; i++) {
        for (int j = y - 1; j <= y + 1; j++) {
            vec2 worley = factor * randvec2(vec2(float(i), float(j)), seed) + vec2(float(i) * factor, float(j) * factor);
            if (minDist > distance(pos, worley)) {
                minDist = distance(pos, worley);
                minWorley = worley;
            }
        }
    }
    return random2(minWorley, seed);
}



void main()
{
  fs_Pos = vs_Pos.xyz;

  float x = vs_Pos.x + u_PlanePos.x;
  float z = vs_Pos.z + u_PlanePos.y;
  vec2 biomeAttr = tempAndRainfall(vec2(x, z));

  float tempBoundary = 0.5;
  float rainBoundary = 0.5;
  if (biomeAttr.y < rainBoundary) {
    fs_Biome = 0.0;
    fs_Height = fbmHeight(x, z, int(fs_Biome)) * 2.0;
  } else {
    fs_Biome = 1.0;
    fs_Height = fbmHeight(x, z, int(fs_Biome)) * 4.0;
  }
  vec4 modelposition = vec4(vs_Pos.x, fs_Height, vs_Pos.z, 1.0);
  modelposition = u_Model * modelposition;
  gl_Position = u_ViewProj * modelposition;
}
