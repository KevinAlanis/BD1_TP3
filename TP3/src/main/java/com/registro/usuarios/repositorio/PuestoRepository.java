package com.registro.usuarios.repositorio;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import com.registro.usuarios.modelo.Puesto;
@Repository
public interface PuestoRepository extends JpaRepository<Puesto, Long> {
}