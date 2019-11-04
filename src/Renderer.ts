import fs0src from "./shader/frag.glsl";
import vs0src from "./shader/vert.glsl";
export function setupRenderer(canvas: HTMLCanvasElement) {
    var vertices = new Float32Array([-1.0, 1.0,
        1.0, 1.0,
    -1.0, -1.0,
        1.0, 1.0,
        1.0, -1.0,
    -1.0, -1.0])
    var gl = canvas.getContext("webgl");

    var vs0el = document.getElementById("vs0");
    var vs0 = gl.createShader(gl.VERTEX_SHADER);
    gl.shaderSource(vs0, vs0src);
    gl.compileShader(vs0);

    var fs0el = document.getElementById("fs0");
    var fs0 = gl.createShader(gl.FRAGMENT_SHADER);
    gl.shaderSource(fs0, fs0src);
    gl.compileShader(fs0);

    var program = gl.createProgram();
    gl.attachShader(program, vs0);
    gl.attachShader(program, fs0);
    gl.linkProgram(program);

    gl.useProgram(program);

    var positionLocation = gl.getAttribLocation(program, "a_position");

    var buffer = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
    const u_resolution = gl.getUniformLocation(program, 'resolution');
    const u_time = gl.getUniformLocation(program, 'time');
    const u_random = gl.getUniformLocation(program, 'random');
    const u_samples = gl.getUniformLocation(program, 'samples');
    let t = 0
    var samples = 0;
    var texture = gl.createTexture();
    gl.bindTexture(gl.TEXTURE_2D, texture);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, 1, 1, 0, gl.RGBA, gl.UNSIGNED_BYTE, new Uint8Array([0, 0, 0, 255]));
    let calcT = 0;
    const scale = 1 / 2;
    let cw = 0;
    let ch = 0;
    function next(v: number) {
        v--;
        v |= v >> 1;
        v |= v >> 2;
        v |= v >> 4;
        v |= v >> 8;
        v |= v >> 16;
        v++;
        return v;
    }
    let samplesPerSecondCounter = 0;
    function draw(dt: number) {
        //t = dt / 1000;
        const displayWidth = canvas.clientWidth;
        const displayHeight = canvas.clientHeight;
        if (cw !== displayWidth || ch !== displayHeight || calcT != t) {
            cw = displayWidth;
            ch = displayHeight;
            canvas.width = displayWidth;
            canvas.height = displayHeight;
            gl.viewport(0, 0, displayWidth, displayHeight);
            gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, 1, 1, 0, gl.RGBA, gl.UNSIGNED_BYTE, new Uint8Array([0, 0, 0, 255]));
            samples = 0;
            calcT = t;
        }

        gl.bufferData(gl.ARRAY_BUFFER, vertices, gl.STATIC_DRAW);
        gl.enableVertexAttribArray(positionLocation);
        gl.vertexAttribPointer(positionLocation, 2, gl.FLOAT, false, 0, 0);
        gl.uniform2f(u_resolution, displayWidth, displayHeight);
        gl.uniform1i(u_samples, samples);
        gl.uniform1f(u_time, t);
        gl.uniform1f(u_random, Math.random());

        gl.drawArrays(gl.TRIANGLES, 0, 6);

        samples += 100;
        samplesPerSecondCounter += 100 * displayWidth * displayHeight;
        requestAnimationFrame(draw);
        gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, canvas);
    }

    draw(0)
}