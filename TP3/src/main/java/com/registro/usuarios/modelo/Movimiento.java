package com.registro.usuarios.modelo;

import javax.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "movimiento")
public class Movimiento {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "valor_doc_id", referencedColumnName = "valorDocumentoIdentidad")
    private Empleado empleado; 

    @ManyToOne
    @JoinColumn(name = "id_tipo_movimiento", referencedColumnName = "id")
    private TipoMovimiento tipoMovimiento;

    @Column(name = "fecha")
    private LocalDateTime fecha;

    @Column(name = "monto")
    private Double monto;

    @Column(name = "post_by_user")
    private String postByUser;

    @Column(name = "post_in_ip")
    private String postInIP;

    @Column(name = "post_time")
    private LocalDateTime postTime;

    // Getters y Setters

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Empleado getEmpleado() {
        return empleado;
    }

    public void setEmpleado(Empleado empleado) {
        this.empleado = empleado;
    }

    public TipoMovimiento getTipoMovimiento() {
        return tipoMovimiento;
    }

    public void setTipoMovimiento(TipoMovimiento tipoMovimiento) {
        this.tipoMovimiento = tipoMovimiento;
    }

    public LocalDateTime getFecha() {
        return fecha;
    }

    public void setFecha(LocalDateTime fecha) {
        this.fecha = fecha;
    }

    public Double getMonto() {
        return monto;
    }

    public void setMonto(Double monto) {
        this.monto = monto;
    }

    public String getPostByUser() {
        return postByUser;
    }

    public void setPostByUser(String postByUser) {
        this.postByUser = postByUser;
    }

    public String getPostInIP() {
        return postInIP;
    }

    public void setPostInIP(String postInIP) {
        this.postInIP = postInIP;
    }

    public LocalDateTime getPostTime() {
        return postTime;
    }

    public void setPostTime(LocalDateTime postTime) {
        this.postTime = postTime;
    }
}
