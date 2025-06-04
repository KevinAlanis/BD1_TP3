package com.registro.usuarios.modelo;

import javax.persistence.*;
import java.time.LocalDate;

@Entity
public class Empleado {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false)
    @JoinColumn(name = "id_puesto", referencedColumnName = "id")
    private Puesto puesto;

    @Column(nullable = false, unique = true)
    private String valorDocumentoIdentidad;

    @Column(nullable = false)
    private String nombre;

    @Column(nullable = false)
    private LocalDate fechaContratacion;

    @Column(nullable = false)
    private Double saldoVacaciones;

    @Column(nullable = false)
    private Boolean esActivo;

    // Constructores
    public Empleado() {
    }

    public Empleado(Puesto puesto, String valorDocumentoIdentidad, String nombre,
                    LocalDate fechaContratacion, Double saldoVacaciones, Boolean esActivo) {
        this.puesto = puesto;
        this.valorDocumentoIdentidad = valorDocumentoIdentidad;
        this.nombre = nombre;
        this.fechaContratacion = fechaContratacion;
        this.saldoVacaciones = saldoVacaciones;
        this.esActivo = esActivo;
    }

    // Getters y Setters
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Puesto getPuesto() {
        return puesto;
    }

    public void setPuesto(Puesto puesto) {
        this.puesto = puesto;
    }

    public String getValorDocumentoIdentidad() {
        return valorDocumentoIdentidad;
    }

    public void setValorDocumentoIdentidad(String valorDocumentoIdentidad) {
        this.valorDocumentoIdentidad = valorDocumentoIdentidad;
    }

    public String getNombre() {
        return nombre;
    }

    public void setNombre(String nombre) {
        this.nombre = nombre;
    }

    public LocalDate getFechaContratacion() {
        return fechaContratacion;
    }

    public void setFechaContratacion(LocalDate fechaContratacion) {
        this.fechaContratacion = fechaContratacion;
    }

    public Double getSaldoVacaciones() {
        return saldoVacaciones;
    }

    public void setSaldoVacaciones(Double saldoVacaciones) {
        this.saldoVacaciones = saldoVacaciones;
    }

    public Boolean getEsActivo() {
        return esActivo;
    }

    public void setEsActivo(Boolean esActivo) {
        this.esActivo = esActivo;
    }
}
