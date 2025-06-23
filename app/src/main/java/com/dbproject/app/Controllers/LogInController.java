package com.dbproject.app.Controllers;

import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.GetMapping;


@RestController
public class LogInController {
    @GetMapping("/")
    String test(){return "Sirve"; }
    
}
