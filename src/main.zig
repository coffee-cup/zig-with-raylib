const std = @import("std");
const rl = @import("raylib");

const num_balls = 10;

const screen_width = 800;
const screen_height = 450;

const frame_rate = 60.0;
const tick_rate = 30.0; // 30 ticks per second

const Ball = struct {
    pos: rl.Vector2,
    vel: rl.Vector2,

    pub fn random_ball(rng: *std.rand.DefaultPrng) Ball {
        return Ball{
            .pos = .{
                .x = rng.random().float(f32) * screen_width,
                .y = rng.random().float(f32) * screen_height,
            },
            .vel = .{
                .x = rng.random().float(f32) * 5 + 5,
                .y = rng.random().float(f32) * 5 + 5,
            },
        };
    }

    pub fn update(self: *Ball) void {
        self.pos.x += self.vel.x;
        self.pos.y += self.vel.y;

        // Bounce off walls
        if (self.pos.x <= 0 or self.pos.x >= screen_width) {
            self.vel.x *= -1;
        }
        if (self.pos.y <= 0 or self.pos.y >= screen_height) {
            self.vel.y *= -1;
        }

        // Ensure the ball stays within the screen bounds
        self.pos.x = std.math.clamp(self.pos.x, 0, screen_width);
        self.pos.y = std.math.clamp(self.pos.y, 0, screen_height);
    }

    pub fn draw(self: Ball) void {
        rl.drawCircle(@intFromFloat(self.pos.x), @intFromFloat(self.pos.y), 10, rl.Color.pink);
    }
};

const GameState = struct {
    balls: []Ball,

    pub fn init(allocator: std.mem.Allocator, rng: *std.rand.DefaultPrng) !GameState {
        var balls = try allocator.alloc(Ball, num_balls);
        errdefer allocator.free(balls);

        var i: usize = 0;
        while (i < num_balls) : (i += 1) {
            balls[i] = Ball.random_ball(rng);
        }

        return GameState{ .balls = balls };
    }

    pub fn deinit(self: *GameState, allocator: std.mem.Allocator) void {
        allocator.free(self.balls);
    }

    pub fn update(self: *GameState) void {
        for (self.balls) |*ball| {
            ball.update();
        }
    }

    pub fn draw(self: *GameState) void {
        for (self.balls) |ball| {
            ball.draw();
        }
    }
};

pub fn main() anyerror!void {
    var rng = std.rand.DefaultPrng.init(@intCast(std.time.milliTimestamp()));

    rl.initWindow(screen_width, screen_height, "pong");
    defer rl.closeWindow();

    const target_tick_rate = 1.0 / tick_rate;
    var accumulated_time: f32 = 0.0;

    rl.setTargetFPS(frame_rate);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create balls
    var game_state = try GameState.init(allocator, &rng);
    defer game_state.deinit(allocator);
    // Main game loop
    while (!rl.windowShouldClose()) {
        const deltaTime = rl.getFrameTime();
        accumulated_time += deltaTime;

        while (accumulated_time >= target_tick_rate) {
            game_state.update();

            accumulated_time -= target_tick_rate;
        }

        rl.beginDrawing();
        rl.clearBackground(rl.Color.black);

        // Draw the game state
        game_state.draw();

        rl.endDrawing();
    }
}
