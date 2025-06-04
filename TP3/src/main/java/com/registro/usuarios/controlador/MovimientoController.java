package com.registro.usuarios.controlador;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import com.registro.usuarios.modelo.Empleado;
import com.registro.usuarios.modelo.Movimiento;
import com.registro.usuarios.repositorio.EmpleadoRepository;
import com.registro.usuarios.repositorio.MovimientoRepository;
import java.util.List;
@Controller
public class MovimientoController {
    @Autowired
    private EmpleadoRepository empleadoRepository;
    @Autowired
    private MovimientoRepository movimientoRepository;
    @GetMapping("/movimientos/buscar")
    public String buscarEmpleadoPorDocumento(@RequestParam(name = "documentoIdentidad", required = false) String documentoIdentidad, Model model) {
        if (documentoIdentidad == null || documentoIdentidad.isEmpty()) {
            model.addAttribute("error", "El documento de identidad es requerido.");
            return "movimientos";
        }
        Empleado empleado = empleadoRepository.findByValorDocumentoIdentidad(documentoIdentidad);
        if (empleado != null) {
            List<Movimiento> movimientos = movimientoRepository.findByEmpleado(empleado);
            model.addAttribute("empleado", empleado);
            model.addAttribute("movimientos", movimientos);
        } else {
            model.addAttribute("empleado", null);
            model.addAttribute("error", "Empleado no encontrado.");
        }
        return "movimientos";
    }
    @GetMapping("/movimientos/agregar")
    public String agregarMovimiento(Model model) {
        List<Empleado> empleados = empleadoRepository.findAll();
        List<Movimiento> Movimiento = movimientoRepository.findAll();
        model.addAttribute("empleados", empleados); 
        model.addAttribute("tiposMovimiento", Movimiento); 
        model.addAttribute("movimiento", new Movimiento()); 

        return "formularioMovimiento"; 
    }
    @PostMapping("/movimientos/guardar")
    public String guardarMovimiento(Movimiento movimiento) {
        movimientoRepository.save(movimiento);
        return "redirect:/movimientos/agregar"; 
    }
}
