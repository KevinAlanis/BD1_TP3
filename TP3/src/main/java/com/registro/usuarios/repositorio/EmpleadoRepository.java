package com.registro.usuarios.repositorio;
import org.springframework.data.jpa.repository.JpaRepository;
import com.registro.usuarios.modelo.Empleado;
public interface EmpleadoRepository extends JpaRepository<Empleado, Long> {
    Empleado findByValorDocumentoIdentidad(String valorDocumentoIdentidad);
}
