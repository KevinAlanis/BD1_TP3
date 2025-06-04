package com.registro.usuarios.repositorio;
import org.springframework.data.jpa.repository.JpaRepository;
import com.registro.usuarios.modelo.Empleado;
import com.registro.usuarios.modelo.Movimiento;
import java.util.List;
public interface MovimientoRepository extends JpaRepository<Movimiento, Long> {
    // Buscar movimientos de un empleado
    List<Movimiento> findByEmpleado(Empleado empleado);
}