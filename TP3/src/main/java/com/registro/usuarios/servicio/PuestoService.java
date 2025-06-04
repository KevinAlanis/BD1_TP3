package com.registro.usuarios.servicio;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import com.registro.usuarios.modelo.Puesto;
import com.registro.usuarios.repositorio.PuestoRepository;
import java.util.List;
import java.util.Optional;
@Service
public class PuestoService {

    private final PuestoRepository puestoRepository;

    @Autowired
    public PuestoService(PuestoRepository puestoRepository) {
        this.puestoRepository = puestoRepository;
    }

    // Método para obtener todos los puestos
    public List<Puesto> obtenerTodosLosPuestos() {
        return puestoRepository.findAll();
    }

    // Método para obtener un puesto por ID
    public Optional<Puesto> obtenerPuestoPorId(Long id) {
        return puestoRepository.findById(id);
    }

    // Método para guardar un nuevo puesto
    public Puesto guardarPuesto(Puesto puesto) {
        return puestoRepository.save(puesto);
    }

    // Método para eliminar un puesto por ID
    public void eliminarPuesto(Long id) {
        puestoRepository.deleteById(id);
    }
}