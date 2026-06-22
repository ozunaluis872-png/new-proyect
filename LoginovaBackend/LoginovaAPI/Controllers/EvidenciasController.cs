using LoginovaAPI.Data;
using LoginovaAPI.DTOs;
using LoginovaAPI.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LoginovaAPI.Controllers;

/// <summary>Controlador que gestiona las operaciones de evidencias (fotos) en el sistema.</summary>
[ApiController]
[Authorize]
[Route("api/[controller]")]
public class EvidenciasController : ControllerBase
{
    private readonly AppDbContext _context;

    public EvidenciasController(AppDbContext context)
    {
        _context = context;
    }

    /// <summary>Obtiene la lista completa de evidencias registradas en el sistema.</summary>
    /// <returns>Lista de todas las evidencias.</returns>
    [HttpGet]
    public async Task<ActionResult<List<Evidencia>>> GetAll()
    {
        return Ok(await _context.Evidencias.AsNoTracking().ToListAsync());
    }

    /// <summary>Obtiene una evidencia por su identificador.</summary>
    [HttpGet("{id:int}")]
    public async Task<ActionResult<Evidencia>> GetById(int id)
    {
        var evidencia = await _context.Evidencias
            .AsNoTracking()
            .SingleOrDefaultAsync(item => item.Id == id);

        return evidencia is null ? NotFound() : Ok(evidencia);
    }

    /// <summary>Obtiene evidencias asociadas a una recogida.</summary>
    [HttpGet("recogida/{recogidaId:int}")]
    public async Task<ActionResult<List<Evidencia>>> GetByRecogida(int recogidaId)
    {
        if (!await _context.Recogidas.AnyAsync(recogida => recogida.Id == recogidaId))
        {
            return NotFound(new { mensaje = "Recogida no existe" });
        }

        var evidencias = await _context.Evidencias
            .AsNoTracking()
            .Where(evidencia => evidencia.RecogidaId == recogidaId)
            .ToListAsync();

        return Ok(evidencias);
    }

    /// <summary>Crea una nueva evidencia (foto) para una recogida especifica.</summary>
    /// <param name="request">Datos de la evidencia a crear (recogida, foto, comentario).</param>
    /// <returns>La evidencia creada con su identificador.</returns>
    [HttpPost]
    public async Task<ActionResult<Evidencia>> Create(EvidenciaRequest request)
    {
        if (!await _context.Recogidas.AnyAsync(r => r.Id == request.RecogidaId))
        {
            return BadRequest(new { mensaje = "Recogida no existe" });
        }

        var evidencia = new Evidencia
        {
            RecogidaId = request.RecogidaId,
            FotoUrl = request.FotoUrl,
            Comentario = request.Comentario,
        };

        _context.Evidencias.Add(evidencia);
        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetAll), evidencia);
    }

    /// <summary>Elimina una evidencia por su identificador.</summary>
    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id)
    {
        var evidencia = await _context.Evidencias.FindAsync(id);
        if (evidencia is null)
        {
            return NotFound();
        }

        _context.Evidencias.Remove(evidencia);
        await _context.SaveChangesAsync();
        return NoContent();
    }
}
