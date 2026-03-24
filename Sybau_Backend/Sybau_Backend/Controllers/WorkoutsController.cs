using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sybau_Backend._Services;
using Sybau_Backend.DTOs;
using Sybau_Backend.Models.Enums;

namespace Sybau_Backend.Controllers;

[Route("[controller]")]
[ApiController]
public class WorkoutsController : ControllerBase
{
    private readonly WorkoutService _workoutService;

    public WorkoutsController(WorkoutService workoutService)
    {
        _workoutService = workoutService;
    }

    [HttpGet]
    public async Task<IActionResult> GetWorkouts([FromQuery] WorkoutCategory? category)
    {
        var workouts = await _workoutService.GetWorkoutsAsync(category);
        return Ok(workouts);
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetWorkoutById(int id)
    {
        var workout = await _workoutService.GetWorkoutByIdAsync(id);
        if (workout == null) return NotFound();
        return Ok(workout);
    }

    [Authorize]
    [HttpPost]
    public async Task<IActionResult> CreateWorkout([FromBody] CreateWorkoutDto dto)
    {
        try
        {
            var workout = await _workoutService.CreateWorkoutAsync(dto);
            return CreatedAtAction(nameof(GetWorkoutById), new { id = workout.Id }, workout);
        }
        catch (ArgumentException e)
        {
            return BadRequest(e.Message);
        }
    }

    [HttpGet("exercises")]
    public async Task<IActionResult> GetExercises([FromQuery] WorkoutCategory? category)
    {
        int? userId = null;
        var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!string.IsNullOrEmpty(userIdClaim) && int.TryParse(userIdClaim, out var uid))
        {
            userId = uid;
        }
        var exercises = await _workoutService.GetExercisesAsync(category, userId);
        return Ok(exercises);
    }

    [Authorize]
    [HttpPost("exercises/log")]
    public async Task<IActionResult> LogExercise([FromBody] LogExerciseDto dto)
    {
        var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out var userId))
            return Unauthorized();

        try
        {
            var result = await _workoutService.LogExerciseAsync(userId, dto.ExerciseId, dto.Reps);
            if (result == null) return NotFound("Übung oder User nicht gefunden.");
            return Ok(result);
        }
        catch (InvalidOperationException e)
        {
            return BadRequest(e.Message);
        }
    }

    [Authorize(Policy = "AdminOnly")]
    [HttpPost("exercises")]
    public async Task<IActionResult> CreateExercise([FromBody] CreateExerciseDto dto)
    {
        try
        {
            var exercise = await _workoutService.CreateExerciseAsync(dto);
            return Ok(exercise);
        }
        catch (ArgumentException e)
        {
            return BadRequest(e.Message);
        }
    }
}