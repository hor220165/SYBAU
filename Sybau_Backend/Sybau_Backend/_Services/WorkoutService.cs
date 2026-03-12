using Microsoft.EntityFrameworkCore;
using Sybau_Backend.Data;
using Sybau_Backend.DTOs;
using Sybau_Backend.Models;
using Sybau_Backend.Models.Enums;

namespace Sybau_Backend._Services;

public class WorkoutService
{
    private readonly FitnessDbContext _context;

    public WorkoutService(FitnessDbContext context)
    {
        _context = context;
    }

    public async Task<ExerciseDto> CreateExerciseAsync(CreateExerciseDto dto)
    {
        if (dto == null) throw new ArgumentNullException(nameof(dto));

        var exercise = new Exercise(dto.Name, dto.Description, dto.Category);
        _context.Exercises.Add(exercise);
        await _context.SaveChangesAsync();

        return new ExerciseDto
        {
            Id = exercise.Id,
            Name = exercise.Name,
            Description = exercise.Description,
            Category = exercise.Category
        };
    }

    public async Task<List<ExerciseDto>> GetExercisesAsync(WorkoutCategory? category)
    {
        var query = _context.Exercises.AsQueryable();

        if (category.HasValue)
        {
            query = query.Where(e => e.Category == category.Value);
        }

        return await query
            .OrderBy(e => e.Name)
            .Select(e => new ExerciseDto
            {
                Id = e.Id,
                Name = e.Name,
                Description = e.Description,
                Category = e.Category
            })
            .ToListAsync();
    }

    public async Task<WorkoutDto> CreateWorkoutAsync(CreateWorkoutDto dto)
    {
        if (dto == null) throw new ArgumentNullException(nameof(dto));
        if (dto.Exercises.Count == 0) throw new ArgumentException("Workout braucht mindestens eine Übung.");

        var exerciseIds = dto.Exercises
            .Select(e => e.ExerciseId)
            .Distinct()
            .ToList();

        if (exerciseIds.Count != dto.Exercises.Count)
            throw new ArgumentException("Doppelte Übungen sind im Workout nicht erlaubt.");

        var exercises = await _context.Exercises
            .Where(e => exerciseIds.Contains(e.Id))
            .ToListAsync();

        if (exercises.Count != exerciseIds.Count)
            throw new ArgumentException("Eine oder mehrere Übungen wurden nicht gefunden.");

        if (dto.Exercises.Any(e => e.DailyLimit < 1))
            throw new ArgumentException("DailyLimit muss mindestens 1 sein.");

        var workout = new Workout(dto.Name, dto.Description, dto.Category);
        _context.Workouts.Add(workout);

        foreach (var item in dto.Exercises)
        {
            var exercise = exercises.Single(e => e.Id == item.ExerciseId);
            _context.WorkoutExercises.Add(new WorkoutExercise(workout, exercise, item.DailyLimit));
        }

        await _context.SaveChangesAsync();

        return await GetWorkoutByIdAsync(workout.Id)
               ?? throw new InvalidOperationException("Workout konnte nach Erstellung nicht geladen werden.");
    }

    public async Task<List<WorkoutDto>> GetWorkoutsAsync(WorkoutCategory? category)
    {
        var query = _context.Workouts
            .Include(w => w.WorkoutExercises)
            .ThenInclude(we => we.Exercise)
            .AsQueryable();

        if (category.HasValue)
        {
            query = query.Where(w => w.Category == category.Value);
        }

        var workouts = await query
            .OrderBy(w => w.Name)
            .ToListAsync();

        return workouts.Select(MapWorkoutToDto).ToList();
    }

    public async Task<WorkoutDto?> GetWorkoutByIdAsync(int id)
    {
        var workout = await _context.Workouts
            .Include(w => w.WorkoutExercises)
            .ThenInclude(we => we.Exercise)
            .FirstOrDefaultAsync(w => w.Id == id);

        if (workout == null) return null;
        return MapWorkoutToDto(workout);
    }

    private static WorkoutDto MapWorkoutToDto(Workout workout)
    {
        return new WorkoutDto
        {
            Id = workout.Id,
            Name = workout.Name,
            Description = workout.Description,
            Category = workout.Category,
            Exercises = workout.WorkoutExercises
                .OrderBy(we => we.Exercise.Name)
                .Select(we => new WorkoutExerciseDto
                {
                    ExerciseId = we.ExerciseId,
                    ExerciseName = we.Exercise.Name,
                    ExerciseCategory = we.Exercise.Category,
                    DailyLimit = we.DailyLimit
                })
                .ToList()
        };
    }
}